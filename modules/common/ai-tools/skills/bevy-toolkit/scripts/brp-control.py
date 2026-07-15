#!/usr/bin/env python3
"""Call and automate a running Bevy app's HTTP Remote Protocol endpoint."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

DEFAULT_URL = "http://127.0.0.1:15702"


class BrpError(RuntimeError):
    """Base error for transport and JSON-RPC failures."""


class BrpTimeout(BrpError):
    """Raised when a wait or artifact deadline expires."""


def json_value(value: str) -> Any:
    if value == "-":
        source = sys.stdin.read()
    elif value.startswith("@"):
        source = Path(value[1:]).read_text()
    else:
        source = value
    try:
        return json.loads(source)
    except json.JSONDecodeError as error:
        raise argparse.ArgumentTypeError(f"invalid JSON: {error}") from error


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    endpoint = parser.add_mutually_exclusive_group()
    endpoint.add_argument(
        "--url", default=DEFAULT_URL, help=f"BRP URL (default: {DEFAULT_URL})"
    )
    endpoint.add_argument("--port", type=int, help="BRP port on 127.0.0.1")
    parser.add_argument(
        "--timeout", type=float, default=3.0, help="request timeout seconds"
    )
    parser.add_argument(
        "--pretty", action="store_true", help="pretty-print JSON output"
    )

    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status", help="probe world.list_resources")

    wait = commands.add_parser("wait", help="wait for BRP readiness")
    wait.add_argument(
        "--seconds", type=float, default=60.0, help="overall wait deadline"
    )
    wait.add_argument("--interval", type=float, default=0.25, help="poll interval")

    call = commands.add_parser("call", help="execute an arbitrary BRP method")
    call.add_argument("method")
    call.add_argument(
        "params", nargs="?", default="{}", type=json_value, help="JSON, @file, or -"
    )

    keys = commands.add_parser("keys", help="send a simultaneous key chord")
    keys.add_argument("keys", nargs="+")
    keys.add_argument("--duration-ms", type=int)

    text = commands.add_parser("type-text", help="type text one character per frame")
    text.add_argument("text")

    screenshot = commands.add_parser(
        "screenshot", help="capture and verify a framebuffer image"
    )
    screenshot.add_argument("path", type=Path)
    screenshot.add_argument("--overwrite", action="store_true")
    screenshot.add_argument("--wait-seconds", type=float, default=10.0)

    commands.add_parser("diagnostics", help="read FPS/frame-time diagnostics")
    commands.add_parser("shutdown", help="request clean extras shutdown")

    click = commands.add_parser("mouse-click", help="click one mouse button")
    click.add_argument(
        "--button",
        default="Left",
        choices=("Left", "Right", "Middle", "Back", "Forward"),
    )

    move = commands.add_parser(
        "mouse-move", help="move mouse by absolute position or delta"
    )
    movement = move.add_mutually_exclusive_group(required=True)
    movement.add_argument("--position", nargs=2, type=float, metavar=("X", "Y"))
    movement.add_argument("--delta", nargs=2, type=float, metavar=("X", "Y"))
    move.add_argument("--window", type=int)

    drag = commands.add_parser("mouse-drag", help="drag between window coordinates")
    drag.add_argument("--start", nargs=2, type=float, required=True, metavar=("X", "Y"))
    drag.add_argument("--end", nargs=2, type=float, required=True, metavar=("X", "Y"))
    drag.add_argument(
        "--button",
        default="Left",
        choices=("Left", "Right", "Middle", "Back", "Forward"),
    )
    drag.add_argument("--frames", type=int, default=30)

    scroll = commands.add_parser("scroll", help="send mouse wheel input")
    scroll.add_argument("--x", type=float, default=0.0)
    scroll.add_argument("--y", type=float, default=0.0)
    scroll.add_argument("--unit", default="Line", choices=("Line", "Pixel"))
    return parser


def endpoint_candidates(url: str) -> list[str]:
    parsed = urllib.parse.urlsplit(url)
    if not parsed.scheme or not parsed.netloc:
        raise BrpError(f"invalid BRP URL: {url}")
    normalized = url.rstrip("/")
    if parsed.path in ("", "/"):
        return [normalized, f"{normalized}/jsonrpc"]
    return [url]


class BrpClient:
    def __init__(self, url: str, timeout: float) -> None:
        self.urls = endpoint_candidates(url)
        self.timeout = timeout
        self.last_url: str | None = None

    def call(self, method: str, params: Any) -> Any:
        payload = json.dumps(
            {"jsonrpc": "2.0", "id": 1, "method": method, "params": params},
            separators=(",", ":"),
        ).encode()
        errors: list[str] = []
        for url in self.urls:
            request = urllib.request.Request(
                url,
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            try:
                with urllib.request.urlopen(request, timeout=self.timeout) as response:
                    body = response.read()
            except (urllib.error.URLError, TimeoutError) as error:
                errors.append(f"{url}: {error}")
                continue
            try:
                decoded = json.loads(body)
            except json.JSONDecodeError as error:
                errors.append(f"{url}: invalid JSON response: {error}")
                continue
            if decoded.get("error") is not None:
                rpc_error = decoded["error"]
                raise BrpError(
                    f"{method}: JSON-RPC {rpc_error.get('code')}: {rpc_error.get('message')}"
                )
            if "result" not in decoded:
                errors.append(f"{url}: response has neither result nor error")
                continue
            self.last_url = url
            return decoded["result"]
        raise BrpError("; ".join(errors) or f"no BRP endpoint accepted {method}")


def emit(value: Any, pretty: bool) -> None:
    print(json.dumps(value, indent=2 if pretty else None, sort_keys=pretty))


def status(client: BrpClient) -> dict[str, Any]:
    resources = client.call("world.list_resources", {})
    count = len(resources) if isinstance(resources, list) else None
    return {
        "status": "running_with_brp",
        "endpoint": client.last_url,
        "resource_count": count,
    }


def wait_ready(client: BrpClient, seconds: float, interval: float) -> dict[str, Any]:
    if seconds <= 0 or interval <= 0:
        raise BrpError("wait seconds and interval must be positive")
    deadline = time.monotonic() + seconds
    last_error = "not attempted"
    while time.monotonic() < deadline:
        try:
            result = status(client)
            result["waited_seconds"] = round(
                seconds - max(0.0, deadline - time.monotonic()), 3
            )
            return result
        except BrpError as error:
            last_error = str(error)
            time.sleep(min(interval, max(0.0, deadline - time.monotonic())))
    raise BrpTimeout(f"BRP not ready after {seconds:g}s: {last_error}")


def screenshot(
    client: BrpClient, path: Path, overwrite: bool, wait_seconds: float
) -> dict[str, Any]:
    destination = path.expanduser().resolve()
    if not destination.parent.is_dir():
        raise BrpError(f"screenshot parent does not exist: {destination.parent}")
    before = destination.stat() if destination.exists() else None
    if before is not None and not overwrite:
        raise BrpError(f"screenshot already exists; pass --overwrite: {destination}")

    result = client.call("brp_extras/screenshot", {"path": str(destination)})
    deadline = time.monotonic() + wait_seconds
    while time.monotonic() < deadline:
        if destination.is_file():
            current = destination.stat()
            changed = before is None or current.st_mtime_ns != before.st_mtime_ns
            if changed and current.st_size > 0:
                return {
                    "result": result,
                    "path": str(destination),
                    "size": current.st_size,
                    "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
                }
        time.sleep(0.05)
    raise BrpTimeout(f"fresh nonempty screenshot not observed: {destination}")


def command_call(client: BrpClient, args: argparse.Namespace) -> Any:
    match args.command:
        case "status":
            return status(client)
        case "wait":
            return wait_ready(client, args.seconds, args.interval)
        case "call":
            return client.call(args.method, args.params)
        case "keys":
            params: dict[str, Any] = {"keys": args.keys}
            if args.duration_ms is not None:
                if not 0 <= args.duration_ms <= 60_000:
                    raise BrpError("duration-ms must be between 0 and 60000")
                params["duration_ms"] = args.duration_ms
            return client.call("brp_extras/send_keys", params)
        case "type-text":
            return client.call("brp_extras/type_text", {"text": args.text})
        case "screenshot":
            return screenshot(client, args.path, args.overwrite, args.wait_seconds)
        case "diagnostics":
            return client.call("brp_extras/get_diagnostics", {})
        case "shutdown":
            return client.call("brp_extras/shutdown", {})
        case "mouse-click":
            return client.call("brp_extras/click_mouse", {"button": args.button})
        case "mouse-move":
            params = {}
            params["position" if args.position is not None else "delta"] = (
                args.position if args.position is not None else args.delta
            )
            if args.window is not None:
                params["window"] = args.window
            return client.call("brp_extras/move_mouse", params)
        case "mouse-drag":
            return client.call(
                "brp_extras/drag_mouse",
                {
                    "button": args.button,
                    "start": args.start,
                    "end": args.end,
                    "frames": args.frames,
                },
            )
        case "scroll":
            return client.call(
                "brp_extras/scroll_mouse", {"x": args.x, "y": args.y, "unit": args.unit}
            )
        case _:
            raise BrpError(f"unsupported command: {args.command}")


def main() -> int:
    args = build_parser().parse_args()
    url = f"http://127.0.0.1:{args.port}" if args.port is not None else args.url
    try:
        result = command_call(BrpClient(url, args.timeout), args)
    except BrpTimeout as error:
        print(f"brp-control: {error}", file=sys.stderr)
        return 3
    except (BrpError, OSError) as error:
        print(f"brp-control: {error}", file=sys.stderr)
        return 1
    emit(result, args.pretty)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
