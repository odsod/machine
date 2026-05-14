"""Snapshot Google Meet DOM via Chrome DevTools Protocol (CDP).

Chrome must be launched with --remote-debugging-port=9224.
Used to investigate the active-speaker signal for Layer 5.
"""

import json
import threading
from datetime import datetime
from pathlib import Path

import httpx


CDP_PORT = 9224
_SNAPSHOT_TIMEOUT = 10


def _get_meet_ws_url(port: int) -> str | None:
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


def _cdp_call(ws_url: str, method: str, params: dict | None = None) -> dict | None:
    """Send a single CDP command over WebSocket, return result."""
    import queue
    import threading
    try:
        import websockets.sync.client as wsc
    except ImportError:
        # Fall back to a raw websocket via httpx — not supported; signal failure
        return None

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
        except Exception as e:
            result_q.put(None)

    t = threading.Thread(target=_run, daemon=True)
    t.start()
    t.join(timeout=_SNAPSHOT_TIMEOUT)
    return result_q.get_nowait() if not result_q.empty() else None


def _snapshot_dom(port: int) -> str | None:
    """Return a pretty-printed JSON snapshot of the Meet DOM, or None on failure."""
    ws_url = _get_meet_ws_url(port)
    if not ws_url:
        return None

    # Use DOM.getDocument + DOM.getOuterHTML for a full snapshot
    result = _cdp_call(ws_url, "DOM.getOuterHTML", {"nodeId": 1})
    if result is None:
        # Try via Runtime.evaluate to get full document HTML
        result = _cdp_call(
            ws_url,
            "Runtime.evaluate",
            {"expression": "document.documentElement.outerHTML", "returnByValue": True},
        )
        if result:
            return result.get("result", {}).get("value")
        return None

    return result.get("outerHTML")


def _snapshot_speaking(port: int) -> str | None:
    """Evaluate JS to find speaking indicators. Returns JSON string or None."""
    ws_url = _get_meet_ws_url(port)
    if not ws_url:
        return None

    # Query every plausible speaking signal in one shot
    js = """
(function() {
  function q(sel) {
    return Array.from(document.querySelectorAll(sel)).map(function(el) {
      return {
        sel: sel,
        tag: el.tagName,
        id: el.id || null,
        cls: el.className || null,
        ariaLabel: el.getAttribute('aria-label') || null,
        ariaLive: el.getAttribute('aria-live') || null,
        text: (el.innerText || '').slice(0, 120),
        children: el.childElementCount
      };
    });
  }
  return JSON.stringify({
    speaking:     q('[aria-label*="speaking" i]'),
    speakerNow:   q('[data-speaker-id]'),
    ariaLive:     q('[aria-live]'),
    activeVideo:  q('video[data-is-speaking]'),
    activeTile:   q('[data-is-dominant-speaker]'),
    micOn:        q('[data-muted="false"]'),
    allMic:       q('[data-muted]'),
  }, null, 2);
})()
"""
    result = _cdp_call(
        ws_url,
        "Runtime.evaluate",
        {"expression": js, "returnByValue": True},
    )
    if result:
        return result.get("result", {}).get("value")
    return None


def dump_dom(interval_secs: float = 5.0, output_dir: str = "~/Tmp/meet-dom", port: int = CDP_PORT):
    """Repeatedly snapshot the Meet DOM via CDP. Ctrl-C to stop.

    Writes two files per snapshot:
      <ts>-speaking.json  — targeted query for all speaker signals
      <ts>-full.html      — full document outerHTML (large, for grep/inspection)
    """
    import time

    out = Path(output_dir).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    print(f"CDP port {port} — writing snapshots to {out}/", flush=True)

    while True:
        ts = datetime.now().strftime("%H%M%S")

        # Always write the targeted speaking query
        done = threading.Event()
        results: list = []

        def _snap():
            speaking = _snapshot_speaking(port)
            full = _snapshot_dom(port)
            results.extend([speaking, full])
            done.set()

        threading.Thread(target=_snap, daemon=True).start()

        if not done.wait(timeout=_SNAPSHOT_TIMEOUT):
            print(f"[{ts}] TIMEOUT — Meet tab not found on port {port}?", flush=True)
        else:
            speaking, full = results[0], results[1]
            if speaking is None:
                print(f"[{ts}] no Meet tab on port {port}", flush=True)
            else:
                sp = out / f"{ts}-speaking.json"
                sp.write_text(speaking)
                notes = []
                try:
                    data = json.loads(speaking)
                    for k, v in data.items():
                        if v:
                            notes.append(f"{k}={len(v)}")
                except Exception:
                    pass
                print(f"[{ts}] speaking → {sp.name}  {' '.join(notes) or '(all empty)'}", flush=True)

            if full:
                fp = out / f"{ts}-full.html"
                fp.write_text(full)

        try:
            time.sleep(interval_secs)
        except KeyboardInterrupt:
            break
