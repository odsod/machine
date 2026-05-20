"""Google Meet speaker detection — backward-compat shim.

Core logic lives in speaker_cdp.py. This module re-exports for existing
tests and provides Meet-specific HTML parsing (extract_speakers).
"""

from __future__ import annotations

from html.parser import HTMLParser

import httpx

from recorder.speaker_cdp import ParticipantState, SpeakerDetector  # noqa: F401

CDP_PORT = 9224


def extract_speakers(html: str, speaking_class: str) -> list[ParticipantState]:
    """Extract participant speaking state from Meet tile HTML.

    Finds [data-participant-id] elements. A participant is speaking if
    speaking_class appears anywhere inside their tile subtree.
    """
    parser = _TileParser(speaking_class)
    parser.feed(html)
    return parser.results


class _TileParser(HTMLParser):

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
