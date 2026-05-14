"""
Lockfile to prevent multiple recorder instances across machines.

The lock lives in the transcript directory (synced via Syncthing), so any
machine on the tailnet sees it. Heartbeat keeps it fresh; stale locks are
ignored on startup.
"""

import json
import os
import socket
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path


HEARTBEAT_INTERVAL = 30
STALE_AFTER = 120


@dataclass
class LockInfo:
    hostname: str
    pid: int
    updated: float


class LockError(Exception):
    pass


class RecorderLock:
    def __init__(self, lock_dir: Path):
        self._path = lock_dir / ".recorder-lock"
        self._last_heartbeat = 0.0

    def acquire(self):
        existing = self._read()
        if existing and not self._is_stale(existing) and not self._is_self(existing):
            age = time.time() - existing.updated
            raise LockError(
                f"Recorder already running on {existing.hostname} "
                f"(pid {existing.pid}, last heartbeat {age:.0f}s ago)"
            )
        self._write()

    def heartbeat(self):
        now = time.time()
        if now - self._last_heartbeat >= HEARTBEAT_INTERVAL:
            self._write()

    def release(self):
        try:
            self._path.unlink()
        except FileNotFoundError:
            pass

    def _read(self) -> LockInfo | None:
        try:
            data = json.loads(self._path.read_text())
            return LockInfo(**data)
        except (FileNotFoundError, json.JSONDecodeError, TypeError, KeyError):
            return None

    def _is_stale(self, lock: LockInfo) -> bool:
        return time.time() - lock.updated > STALE_AFTER

    def _is_self(self, lock: LockInfo) -> bool:
        return lock.hostname == _hostname() and lock.pid == os.getpid()

    def _write(self):
        info = LockInfo(hostname=_hostname(), pid=os.getpid(), updated=time.time())
        tmp = self._path.with_suffix(".tmp")
        tmp.write_text(json.dumps(info.__dict__))
        tmp.rename(self._path)
        self._last_heartbeat = time.time()


def _hostname() -> str:
    return socket.gethostname()
