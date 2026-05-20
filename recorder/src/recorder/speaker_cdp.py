"""Multi-platform speaker detection via Chrome DevTools Protocol.

Scans configured CDP ports for active meeting tabs (Meet, Teams), auto-detects
the platform, and discovers the speaking indicator class via temporal diffing.
No hardcoded CSS classes — discovery adapts to any deploy.
"""

from __future__ import annotations

import json
from dataclasses import dataclass

import httpx


@dataclass
class PlatformConfig:
    name: str
    url_pattern: str
    snapshot_js: str
    poll_js_template: str


MEET_PLATFORM = PlatformConfig(
    name="meet",
    url_pattern="meet.google.com",
    snapshot_js=r"""
(function() {
  function getName(tile) {
    var names = Array.from(tile.querySelectorAll('.notranslate'))
      .map(function(n) { return n.innerText.trim(); })
      .filter(function(s) {
        return s.length > 2 && s.length < 50
          && s[0] === s[0].toUpperCase()
          && s.includes(' ');
      });
    return names[0] || null;
  }
  return JSON.stringify(
    Array.from(document.querySelectorAll('[data-participant-id]')).map(function(t) {
      var name = getName(t);
      var classes = new Set();
      t.querySelectorAll('[class]').forEach(function(el) {
        el.classList.forEach(function(c) { classes.add(c); });
      });
      return {name: name, classes: Array.from(classes)};
    }).filter(function(x) { return x.name; })
  );
})()
""",
    poll_js_template=r"""
(function() {{
  function getName(tile) {{
    var names = Array.from(tile.querySelectorAll('.notranslate'))
      .map(function(n) {{ return n.innerText.trim(); }})
      .filter(function(s) {{
        return s.length > 2 && s.length < 50
          && s[0] === s[0].toUpperCase()
          && s.includes(' ');
      }});
    return names[0] || null;
  }}
  return JSON.stringify(
    Array.from(document.querySelectorAll('[data-participant-id]')).map(function(t) {{
      var name = getName(t);
      if (!name) return null;
      var speaking = !!t.querySelector('.{speaking_class}') || !!t.closest('.{speaking_class}');
      return {{name: name, speaking: speaking}};
    }}).filter(Boolean)
  );
}})()
""",
)

TEAMS_PLATFORM = PlatformConfig(
    name="teams",
    url_pattern="teams.microsoft.com",
    snapshot_js=r"""
(function() {
  return JSON.stringify(
    Array.from(document.querySelectorAll('[data-tid="voice-level-stream-outline"]')).map(function(el) {
      var p = el.parentElement;
      var tid = p ? p.getAttribute('data-tid') : null;
      var name = (tid && tid.length > 2 && tid.length < 80) ? tid : null;
      var classes = el.className.split(/\s+/);
      return {name: name, classes: classes};
    }).filter(function(x) { return x.name; })
  );
})()
""",
    poll_js_template=r"""
(function() {{
  return JSON.stringify(
    Array.from(document.querySelectorAll('[data-tid="voice-level-stream-outline"]')).map(function(el) {{
      var p = el.parentElement;
      var tid = p ? p.getAttribute('data-tid') : null;
      if (!tid || tid.length <= 2) return null;
      var speaking = el.classList.contains('{speaking_class}');
      return {{name: tid, speaking: speaking}};
    }}).filter(Boolean)
  );
}})()
""",
)

PLATFORMS: list[PlatformConfig] = [MEET_PLATFORM, TEAMS_PLATFORM]


@dataclass
class ParticipantState:
    name: str
    speaking: bool


def _cdp_eval(ws_url: str, js: str) -> str | None:
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


def find_meeting_tab(ports: list[int]) -> tuple[str, PlatformConfig] | None:
    """Scan CDP ports for an active meeting tab. Returns (ws_url, platform) or None."""
    for port in ports:
        try:
            resp = httpx.get(f"http://localhost:{port}/json", timeout=5)
            resp.raise_for_status()
            tabs = resp.json()
        except Exception:
            continue
        for tab in tabs:
            url = tab.get("url", "")
            if tab.get("type") != "page":
                continue
            for platform in PLATFORMS:
                if platform.url_pattern in url:
                    ws_url = tab.get("webSocketDebuggerUrl")
                    if ws_url:
                        return (ws_url, platform)
    return None


class SpeakerDetector:
    """Platform-agnostic speaker detector with temporal-diff class discovery.

    Scans configured CDP ports for meeting tabs, auto-detects the platform,
    and discovers the speaking indicator class by diffing tile class sets
    between consecutive polls.
    """

    def __init__(self, ports: list[int]):
        self._ports = ports
        self._active_ws_url: str | None = None
        self._active_platform: PlatformConfig | None = None
        self._speaking_class: str | None = None
        self._prev_snapshot: dict[str, set[str]] | None = None

    @property
    def speaking_class(self) -> str | None:
        return self._speaking_class

    @property
    def active_platform(self) -> PlatformConfig | None:
        return self._active_platform

    def poll(self) -> list[ParticipantState] | None:
        result = find_meeting_tab(self._ports)
        if result is None:
            return None

        ws_url, platform = result

        if ws_url != self._active_ws_url:
            self._active_ws_url = ws_url
            self._active_platform = platform
            self._speaking_class = None
            self._prev_snapshot = None

        if self._speaking_class:
            return self._poll_cached(ws_url, platform)
        return self._poll_discovery(ws_url, platform)

    def _poll_cached(self, ws_url: str, platform: PlatformConfig) -> list[ParticipantState] | None:
        js = platform.poll_js_template.format(speaking_class=self._speaking_class)
        val = _cdp_eval(ws_url, js)
        if not val:
            return None
        data = json.loads(val)
        return [ParticipantState(name=d["name"], speaking=d["speaking"]) for d in data]

    def _poll_discovery(self, ws_url: str, platform: PlatformConfig) -> list[ParticipantState] | None:
        val = _cdp_eval(ws_url, platform.snapshot_js)
        if not val:
            return None
        data = json.loads(val)

        current: dict[str, set[str]] = {}
        for tile in data:
            current[tile["name"]] = set(tile["classes"])

        names = list(current.keys())

        if self._prev_snapshot is not None:
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
