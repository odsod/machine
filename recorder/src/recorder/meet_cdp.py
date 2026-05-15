"""Google Meet speaker detection via Chrome DevTools Protocol.

Polls the Meet tab for active speaker state. Requires Chrome launched with
--remote-debugging-port=9224 (configured via user-data-dir).

Detection is class-name-agnostic: on first speech event, the speaking
indicator class is auto-discovered by diffing tile class sets between polls.
Once discovered, the class is cached for fast subsequent lookups.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from html.parser import HTMLParser

import httpx


CDP_PORT = 9224


@dataclass
class ParticipantState:
    name: str
    speaking: bool


def extract_speakers(html: str, speaking_class: str) -> list[ParticipantState]:
    """Extract participant speaking state from Meet tile HTML.

    Finds [data-participant-id] elements. A participant is speaking if
    speaking_class appears anywhere inside their tile subtree.
    """
    parser = _TileParser(speaking_class)
    parser.feed(html)
    return parser.results


class _TileParser(HTMLParser):
    """Finds [data-participant-id] tiles and checks for speaking indicator inside."""

    def __init__(self, speaking_class: str):
        super().__init__()
        self._speaking_class = speaking_class
        self.results: list[ParticipantState] = []
        self._in_tile = False
        self._tile_speaking = False
        self._tile_name = ""
        self._depth = 0

    def handle_starttag(self, tag, attrs):
        attr_dict = dict(attrs)
        classes = attr_dict.get("class", "").split()

        if "data-participant-id" in attr_dict:
            self._in_tile = True
            self._tile_speaking = self._speaking_class in classes
            self._tile_name = ""
            self._depth = 0

        if self._in_tile:
            self._depth += 1
            if self._speaking_class in classes:
                self._tile_speaking = True

    def handle_endtag(self, tag):
        if self._in_tile:
            self._depth -= 1
            if self._depth <= 0:
                if self._tile_name:
                    self.results.append(
                        ParticipantState(name=self._tile_name, speaking=self._tile_speaking)
                    )
                self._in_tile = False

    def handle_data(self, data):
        if self._in_tile and not self._tile_name:
            text = data.strip()
            if len(text) > 2 and len(text) < 50 and text[0].isupper() and " " in text:
                self._tile_name = text


def get_meet_ws_url(port: int = CDP_PORT) -> str | None:
    """Find the Meet tab's WebSocket debugger URL."""
    try:
        resp = httpx.get(f"http://localhost:{port}/json", timeout=5)
        resp.raise_for_status()
        for tab in resp.json():
            url = tab.get("url", "")
            if "meet.google.com" in url and tab.get("type") == "page":
                return tab.get("webSocketDebuggerUrl")
    except Exception:
        pass
    return None


_NAME_FILTER_JS = r"""
function _getName(tile) {
  var names = Array.from(tile.querySelectorAll('.notranslate'))
    .map(function(n) { return n.innerText.trim(); })
    .filter(function(s) {
      return s.length > 2 && s.length < 50
        && s[0] === s[0].toUpperCase()
        && s.includes(' ');
    });
  return names[0] || null;
}
"""


def _make_snapshot_js() -> str:
    """JS that returns per-tile name + class set for diffing."""
    return _NAME_FILTER_JS + r"""
JSON.stringify(Array.from(document.querySelectorAll('[data-participant-id]')).map(function(t) {
  var name = _getName(t);
  var classes = new Set();
  t.querySelectorAll('[class]').forEach(function(el) {
    el.classList.forEach(function(c) { classes.add(c); });
  });
  return {name: name, classes: Array.from(classes)};
}).filter(function(x) { return x.name; }))
"""


def _make_poll_js(speaking_class: str) -> str:
    """JS that checks for the cached speaking class."""
    return _NAME_FILTER_JS + (
        "JSON.stringify(Array.from(document.querySelectorAll('[data-participant-id]')).map(function(t) {"
        "  var name = _getName(t);"
        "  if (!name) return null;"
        f"  var speaking = !!t.querySelector('.{speaking_class}') || !!t.closest('.{speaking_class}');"
        "  return {name: name, speaking: speaking};"
        "}).filter(Boolean))"
    )


def _cdp_eval(ws_url: str, js: str) -> str | None:
    """Evaluate JS expression via CDP, return result value string."""
    import websockets.sync.client as wsc

    try:
        with wsc.connect(ws_url, open_timeout=5) as ws:
            ws.send(json.dumps({
                "id": 1,
                "method": "Runtime.evaluate",
                "params": {"expression": js, "returnByValue": True},
            }))
            msg = json.loads(ws.recv())
            return msg.get("result", {}).get("result", {}).get("value")
    except Exception:
        return None


class SpeakerDetector:
    """Stateful speaker detector that discovers the speaking class via temporal diff.

    Polls the Meet DOM for per-tile class sets. When a class appears on one tile
    that wasn't there in the previous poll, that class is the speaking indicator.
    Once discovered, uses it for fast direct lookups until the page reloads.

    Cold start: no spk events fire until the first speaker *change* is observed
    (typically within the first minute of any real meeting).

    Usage:
        detector = SpeakerDetector()
        states = detector.poll()  # returns list[ParticipantState] | None
    """

    def __init__(self, port: int = CDP_PORT):
        self._port = port
        self._speaking_class: str | None = None
        self._prev_snapshot: dict[str, set[str]] | None = None

    @property
    def speaking_class(self) -> str | None:
        return self._speaking_class

    def poll(self) -> list[ParticipantState] | None:
        ws_url = get_meet_ws_url(self._port)
        if not ws_url:
            return None

        if self._speaking_class:
            return self._poll_cached(ws_url)
        return self._poll_discovery(ws_url)

    def _poll_cached(self, ws_url: str) -> list[ParticipantState] | None:
        js = _make_poll_js(self._speaking_class)
        val = _cdp_eval(ws_url, js)
        if not val:
            return None
        data = json.loads(val)
        return [ParticipantState(name=d["name"], speaking=d["speaking"]) for d in data]

    def _poll_discovery(self, ws_url: str) -> list[ParticipantState] | None:
        """Snapshot tile class sets and diff against previous to find the speaking class."""
        js = _make_snapshot_js()
        val = _cdp_eval(ws_url, js)
        if not val:
            return None
        data = json.loads(val)

        current: dict[str, set[str]] = {}
        for tile in data:
            current[tile["name"]] = set(tile["classes"])

        names = list(current.keys())

        if self._prev_snapshot is not None:
            # Find classes that changed on any tile since last poll
            changed: set[str] = set()
            for name in current:
                prev = self._prev_snapshot.get(name, set())
                changed |= (current[name] - prev) | (prev - current[name])

            if changed:
                self._speaking_class = min(changed, key=len)
                self._prev_snapshot = current
                return [
                    ParticipantState(name=n, speaking=self._speaking_class in current[n])
                    for n in names
                ]

        self._prev_snapshot = current
        return [ParticipantState(name=n, speaking=False) for n in names]
