"""Per-session grant state and the decision log."""

from __future__ import annotations

import contextlib
import fcntl
import json
import os
import re
import stat
import time
from pathlib import Path
from typing import Any

STATE_DIR_NAME = "khanelinix-authority-gate"


def state_root() -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if runtime:
        return Path(runtime) / STATE_DIR_NAME
    state_home = os.environ.get("XDG_STATE_HOME")
    base = Path(state_home) if state_home else Path.home() / ".local/state"
    return base / "khanelinix/authority-gate"


def state_path(payload: dict[str, Any], root: Path) -> Path | None:
    session_id = payload.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        return None
    return root / f"{re.sub(r'[^A-Za-z0-9_.-]', '_', session_id)}.json"


def ensure_root(root: Path) -> None:
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    metadata = root.lstat()
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        raise OSError(f"authority gate state root is not a directory: {root}")
    if metadata.st_uid != os.getuid():
        raise OSError(f"authority gate state root is not owned by this user: {root}")
    root.chmod(0o700)


@contextlib.contextmanager
def locked_state(path: Path):
    ensure_root(path.parent)
    flags = os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(path.with_suffix(".lock"), flags, 0o600)
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid():
            raise OSError(f"invalid authority gate lock: {path}")
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        yield
    finally:
        os.close(descriptor)


def read_state(path: Path) -> dict[str, set[str]]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        payload = {}
    except (json.JSONDecodeError, OSError) as error:
        raise OSError(f"invalid authority gate state: {path}") from error
    if not isinstance(payload, dict):
        raise OSError(f"invalid authority gate state: {path}")
    state: dict[str, set[str]] = {}
    for key in ("turn", "session", "pending", "carry"):
        value = payload.get(key, [])
        if not isinstance(value, list) or not all(
            isinstance(item, str) for item in value
        ):
            raise OSError(f"invalid authority gate state: {path}")
        state[key] = set(value)
    return state


def write_state(path: Path, state: dict[str, set[str]]) -> None:
    if not any(state.values()):
        with contextlib.suppress(FileNotFoundError):
            path.unlink()
        return
    import tempfile

    descriptor, temporary = tempfile.mkstemp(prefix=".gate-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump({key: sorted(value) for key, value in state.items()}, handle)
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    finally:
        with contextlib.suppress(FileNotFoundError):
            os.unlink(temporary)


def log_decision(
    provider: str, payload: dict[str, Any], labels: list[str], code: str
) -> None:
    state_home = os.environ.get("XDG_STATE_HOME")
    base = Path(state_home) if state_home else Path.home() / ".local/state"
    log = base / "khanelinix/authority-gate/decisions.jsonl"
    entry = {
        "time": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "provider": provider,
        "session": str(payload.get("session_id", ""))[:12],
        "worker": payload.get("agent_id") is not None,
        "actions": labels,
        "decision": code,
    }
    with contextlib.suppress(OSError):
        log.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        descriptor = os.open(log, os.O_CREAT | os.O_APPEND | os.O_WRONLY, 0o600)
        with os.fdopen(descriptor, "a", encoding="utf-8") as handle:
            handle.write(json.dumps(entry) + "\n")
