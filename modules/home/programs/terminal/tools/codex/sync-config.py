import os
import sys
import tempfile
from pathlib import Path

import tomlkit


def read_config(path):
    return tomlkit.parse(path.read_text()) if path.exists() else tomlkit.document()


def reconcile(current, previous, declared):
    for key in previous.keys() | declared.keys():
        # Unchanged declarations preserve Codex's saved user selections.
        if key in previous and key in declared and previous[key] == declared[key]:
            continue
        if key not in declared:
            if key in current and current[key] == previous[key]:
                del current[key]
        elif isinstance(declared[key], dict) and isinstance(current.get(key), dict):
            old = previous.get(key, {})
            reconcile(current[key], old if isinstance(old, dict) else {}, declared[key])
        else:
            current[key] = declared[key]


def write_atomic(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=path.parent, delete=False
        ) as handle:
            temporary = Path(handle.name)
            handle.write(content)
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def sync_config(source, target, snapshot):
    declared = read_config(source)
    current = read_config(target)
    previous = read_config(snapshot) if target.exists() else tomlkit.document()
    reconcile(current, previous, declared)
    rendered = tomlkit.dumps(current)
    if target.is_symlink() or not target.exists() or target.read_text() != rendered:
        write_atomic(target, rendered)
    else:
        target.chmod(target.stat().st_mode | 0o600)
    write_atomic(snapshot, source.read_text())


if __name__ == "__main__":
    os.umask(0o077)
    sync_config(*(Path(argument) for argument in sys.argv[1:]))
