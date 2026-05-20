"""Snapshot meeting DOM via Chrome DevTools Protocol (CDP).

Auto-detects the active meeting platform (Meet, Teams) across configured
CDP ports and writes periodic DOM snapshots for debugging speaker detection.
"""

import json
import threading
import time
from datetime import datetime
from pathlib import Path

import httpx

from recorder.speaker_cdp import PLATFORMS, PlatformConfig, _cdp_eval, find_meeting_tab


_SNAPSHOT_TIMEOUT = 10


def _cdp_call(ws_url: str, method: str, params: dict | None = None) -> dict | None:
    import queue

    import websockets.sync.client as wsc

    result_q: queue.Queue = queue.Queue()

    def _run():
        try:
            with wsc.connect(ws_url, open_timeout=5) as ws:
                ws.send(json.dumps({"id": 1, "method": method, "params": params or {}}))
                while True:
                    msg = json.loads(ws.recv())
                    if msg.get("id") == 1:
                        result_q.put(msg.get("result"))
                        return
        except Exception:
            result_q.put(None)

    t = threading.Thread(target=_run, daemon=True)
    t.start()
    t.join(timeout=_SNAPSHOT_TIMEOUT)
    return result_q.get_nowait() if not result_q.empty() else None


def _snapshot_full_dom(ws_url: str) -> str | None:
    result = _cdp_call(
        ws_url,
        "Runtime.evaluate",
        {"expression": "document.documentElement.outerHTML", "returnByValue": True},
    )
    if result:
        return result.get("result", {}).get("value")
    return None


def _snapshot_tiles(ws_url: str, platform: PlatformConfig) -> str | None:
    val = _cdp_eval(ws_url, platform.snapshot_js)
    return val


def dump_dom(
    interval_secs: float = 5.0,
    output_dir: str = "~/Tmp/meeting-dom",
    ports: list[int] | None = None,
):
    """Repeatedly snapshot the meeting DOM via CDP. Ctrl-C to stop.

    Auto-detects platform across configured ports. Writes per snapshot:
      <ts>-tiles.json   — tile class sets (for diffing speaker detection)
      <ts>-full.html    — full document outerHTML
    """
    if ports is None:
        ports = [9224, 9223]

    out = Path(output_dir).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    print(f"Scanning CDP ports {ports} — writing snapshots to {out}/", flush=True)

    while True:
        ts = datetime.now().strftime("%H%M%S")

        result = find_meeting_tab(ports)
        if result is None:
            print(f"[{ts}] no meeting tab found on ports {ports}", flush=True)
            try:
                time.sleep(interval_secs)
            except KeyboardInterrupt:
                break
            continue

        ws_url, platform = result
        print(f"[{ts}] {platform.name} detected", end="", flush=True)

        done = threading.Event()
        results: list = []

        def _snap():
            tiles = _snapshot_tiles(ws_url, platform)
            full = _snapshot_full_dom(ws_url)
            results.extend([tiles, full])
            done.set()

        threading.Thread(target=_snap, daemon=True).start()

        if not done.wait(timeout=_SNAPSHOT_TIMEOUT):
            print(" TIMEOUT", flush=True)
        else:
            tiles, full = results[0], results[1]
            if tiles:
                tp = out / f"{ts}-tiles.json"
                tp.write_text(tiles)
                try:
                    data = json.loads(tiles)
                    print(f" — {len(data)} tiles", end="", flush=True)
                except Exception:
                    pass
            if full:
                fp = out / f"{ts}-full.html"
                fp.write_text(full)
            print("", flush=True)

        try:
            time.sleep(interval_secs)
        except KeyboardInterrupt:
            break
