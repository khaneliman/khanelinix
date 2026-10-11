"""Inert stdio LSP recorder for native Helix regression fixtures."""

import json
import os
import sys
from pathlib import Path

while True:
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            raise SystemExit(0)
        if line in (b"\r\n", b"\n"):
            break
        key, value = line.decode().split(":", 1)
        headers[key.lower()] = value.strip()
    message = json.loads(sys.stdin.buffer.read(int(headers["content-length"])))
    with Path(os.environ["HELIX_PROBE_LOG"]).open("a") as log:
        log.write(json.dumps({**message, "recorder": Path(sys.argv[0]).name}) + "\n")
    if "id" in message:
        result = (
            {"capabilities": {"textDocumentSync": 1}}
            if message.get("method") == "initialize"
            else None
        )
        data = json.dumps(
            {"jsonrpc": "2.0", "id": message["id"], "result": result}
        ).encode()
        sys.stdout.buffer.write(f"Content-Length: {len(data)}\r\n\r\n".encode() + data)
        sys.stdout.buffer.flush()
    if message.get("method") == "exit":
        raise SystemExit(0)
