#!/usr/bin/env python3
"""Call and automate a running Bevy app's HTTP Remote Protocol endpoint."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path
from typing import Any

DEFAULT_URL = "http://127.0.0.1:15702"
MISSING = object()
MUTATING_COMMANDS = {
    "keys",
    "mouse-click",
    "mouse-drag",
    "mouse-move",
    "screenshot",
    "scroll",
    "shutdown",
    "type-text",
}
READ_ONLY_METHODS = {
    "brp_extras/get_diagnostics",
    "registry.schema",
    "rpc.discover",
    "world.get_components",
    "world.get_resources",
    "world.list_components",
    "world.list_resources",
    "world.query",
}


class BrpError(RuntimeError):
    """Base error for transport and JSON-RPC failures."""


class BrpTimeout(BrpError):
    """Raised when a wait or artifact deadline expires."""


class BrpPrerequisite(BrpError):
    """Raised when a required safety precondition is missing."""


class BrpVerification(BrpError):
    """Raised when readback does not match the expected target or artifact."""


def json_value(value: str) -> Any:
    try:
        if value == "-":
            source = sys.stdin.read()
        elif value.startswith("@"):
            source = Path(value[1:]).read_text()
        else:
            source = value
    except OSError as error:
        raise argparse.ArgumentTypeError(f"cannot read JSON input: {error}") from error
    try:
        return json.loads(source)
    except json.JSONDecodeError as error:
        raise argparse.ArgumentTypeError(f"invalid JSON: {error}") from error


def finite_float(value: str) -> float:
    try:
        parsed = float(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError(f"expected number: {value}") from error
    if not math.isfinite(parsed):
        raise argparse.ArgumentTypeError("value must be finite")
    return parsed


def positive_float(value: str) -> float:
    parsed = finite_float(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be finite and positive")
    return parsed


def positive_int(value: str) -> int:
    try:
        parsed = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError(f"expected integer: {value}") from error
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be positive")
    return parsed


def brp_port(value: str) -> int:
    parsed = positive_int(value)
    if parsed > 65_535:
        raise argparse.ArgumentTypeError("port must be at most 65535")
    return parsed


def key_duration(value: str) -> int:
    try:
        parsed = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError(f"expected integer: {value}") from error
    if not 0 <= parsed <= 60_000:
        raise argparse.ArgumentTypeError("duration must be between 0 and 60000")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    endpoint = parser.add_mutually_exclusive_group()
    endpoint.add_argument(
        "--url", default=DEFAULT_URL, help=f"BRP URL (default: {DEFAULT_URL})"
    )
    endpoint.add_argument("--port", type=brp_port, help="BRP port on 127.0.0.1")
    parser.add_argument(
        "--timeout", type=positive_float, default=3.0, help="request timeout seconds"
    )
    parser.add_argument(
        "--pretty", action="store_true", help="pretty-print JSON output"
    )
    parser.add_argument(
        "--identity-method",
        help="read-only BRP method used to identify the mutation target",
    )
    parser.add_argument(
        "--identity-params",
        type=json_value,
        default={},
        help="identity method parameters as JSON, @file, or -",
    )
    parser.add_argument(
        "--identity-expected",
        type=json_value,
        default=MISSING,
        help="exact expected identity result as JSON, @file, or -",
    )
    parser.add_argument(
        "--allow-unguarded-mutation",
        action="store_true",
        help="explicitly allow mutation without app/session identity verification",
    )

    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status", help="probe world.list_resources")

    wait = commands.add_parser("wait", help="wait for BRP readiness")
    wait.add_argument(
        "--seconds", type=positive_float, default=60.0, help="overall wait deadline"
    )
    wait.add_argument(
        "--interval", type=positive_float, default=0.25, help="poll interval"
    )

    call = commands.add_parser("call", help="execute an arbitrary BRP method")
    call.add_argument("method")
    call.add_argument(
        "params", nargs="?", default="{}", type=json_value, help="JSON, @file, or -"
    )
    call.add_argument(
        "--read-only",
        action="store_true",
        help="use an allowlisted observational method without an identity guard",
    )

    keys = commands.add_parser("keys", help="send a simultaneous key chord")
    keys.add_argument("keys", nargs="+")
    keys.add_argument("--duration-ms", type=key_duration)

    text = commands.add_parser("type-text", help="type text one character per frame")
    text.add_argument("text")

    screenshot = commands.add_parser(
        "screenshot", help="capture and verify a framebuffer image"
    )
    screenshot.add_argument("path", type=Path)
    screenshot.add_argument("--overwrite", action="store_true")
    screenshot.add_argument("--wait-seconds", type=positive_float, default=10.0)

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
    movement.add_argument("--position", nargs=2, type=finite_float, metavar=("X", "Y"))
    movement.add_argument("--delta", nargs=2, type=finite_float, metavar=("X", "Y"))
    move.add_argument("--window", type=int)

    drag = commands.add_parser("mouse-drag", help="drag between window coordinates")
    drag.add_argument(
        "--start", nargs=2, type=finite_float, required=True, metavar=("X", "Y")
    )
    drag.add_argument(
        "--end", nargs=2, type=finite_float, required=True, metavar=("X", "Y")
    )
    drag.add_argument(
        "--button",
        default="Left",
        choices=("Left", "Right", "Middle", "Back", "Forward"),
    )
    drag.add_argument("--frames", type=positive_int, default=30)

    scroll = commands.add_parser("scroll", help="send mouse wheel input")
    scroll.add_argument("--x", type=finite_float, default=0.0)
    scroll.add_argument("--y", type=finite_float, default=0.0)
    scroll.add_argument("--unit", default="Line", choices=("Line", "Pixel"))
    return parser


def endpoint_candidates(url: str) -> list[str]:
    try:
        parsed = urllib.parse.urlsplit(url)
        _ = parsed.port
    except ValueError as error:
        raise BrpError(f"invalid BRP URL: {url}: {error}") from error
    if (
        parsed.scheme not in ("http", "https")
        or parsed.hostname is None
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
    ):
        raise BrpError(f"invalid BRP URL: {url}")
    if parsed.path in ("", "/"):
        root = urllib.parse.urlunsplit((parsed.scheme, parsed.netloc, "", "", ""))
        return [root, f"{root}/jsonrpc"]
    return [urllib.parse.urlunsplit(parsed)]


class BrpClient:
    def __init__(self, url: str, timeout: float) -> None:
        self.urls = endpoint_candidates(url)
        self.timeout = timeout
        self.last_url: str | None = None

    def request(self, url: str, method: str, params: Any) -> Any:
        request_id = uuid.uuid4().hex
        payload = json.dumps(
            {
                "jsonrpc": "2.0",
                "id": request_id,
                "method": method,
                "params": params,
            },
            separators=(",", ":"),
        ).encode()
        request = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                body = response.read()
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            raise BrpError(f"{url}: {error}") from error
        try:
            decoded = json.loads(body)
        except json.JSONDecodeError as error:
            raise BrpError(f"{url}: invalid JSON response: {error}") from error
        if not isinstance(decoded, dict):
            raise BrpError(f"{url}: response is not a JSON-RPC object")
        if decoded.get("jsonrpc") != "2.0":
            raise BrpError(f"{url}: response has invalid JSON-RPC version")
        if decoded.get("id", MISSING) != request_id:
            raise BrpError(f"{url}: response ID does not match request")
        if decoded.get("error") is not None:
            rpc_error = decoded["error"]
            if isinstance(rpc_error, dict):
                code = rpc_error.get("code")
                message = rpc_error.get("message")
            else:
                code = None
                message = rpc_error
            raise BrpError(f"{method}: JSON-RPC {code}: {message}")
        if "result" not in decoded:
            raise BrpError(f"{url}: response has neither result nor error")
        return decoded["result"]

    def probe(self) -> Any:
        if self.last_url is not None:
            return self.request(self.last_url, "world.list_resources", {})

        errors: list[str] = []
        for url in self.urls:
            try:
                result = self.request(url, "world.list_resources", {})
            except BrpError as error:
                errors.append(str(error))
                continue
            self.last_url = url
            return result
        raise BrpError("; ".join(errors) or "no BRP endpoint accepted readiness probe")

    def resolve(self) -> str:
        self.probe()
        if self.last_url is None:
            raise BrpError("BRP endpoint probe succeeded without selecting an endpoint")
        return self.last_url

    def call(self, method: str, params: Any) -> Any:
        endpoint = self.last_url or self.resolve()
        return self.request(endpoint, method, params)


def emit(value: Any, pretty: bool) -> None:
    print(json.dumps(value, indent=2 if pretty else None, sort_keys=pretty))


def status(client: BrpClient) -> dict[str, Any]:
    resources = client.probe()
    count = len(resources) if isinstance(resources, list) else None
    return {
        "state": "running_with_brp",
        "resource_count": count,
    }


def wait_ready(client: BrpClient, seconds: float, interval: float) -> dict[str, Any]:
    if seconds <= 0 or interval <= 0:
        raise BrpPrerequisite("wait seconds and interval must be positive")
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
    if destination.exists() and not overwrite:
        raise BrpError(f"screenshot already exists; pass --overwrite: {destination}")

    staging = destination.with_name(f".{destination.name}.brp-{uuid.uuid4().hex}.tmp")
    try:
        result = client.call("brp_extras/screenshot", {"path": str(staging)})
        deadline = time.monotonic() + wait_seconds
        while time.monotonic() < deadline:
            if staging.is_file() and staging.stat().st_size > 0:
                staging.replace(destination)
                return {
                    "result": result,
                    "path": str(destination),
                    "size": destination.stat().st_size,
                    "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
                }
            time.sleep(0.05)
    finally:
        staging.unlink(missing_ok=True)
    raise BrpVerification(f"fresh nonempty screenshot not observed: {destination}")


def is_mutating(args: argparse.Namespace) -> bool:
    if args.command == "call":
        return not args.read_only
    return args.command in MUTATING_COMMANDS


def verify_mutation_target(
    client: BrpClient, args: argparse.Namespace
) -> dict[str, Any] | None:
    if (
        args.command == "call"
        and args.read_only
        and args.method not in READ_ONLY_METHODS
    ):
        raise BrpPrerequisite(
            f"--read-only is not permitted for unlisted method {args.method!r}"
        )
    if not is_mutating(args):
        return None

    has_identity = (
        args.identity_method is not None or args.identity_expected is not MISSING
    )
    if args.allow_unguarded_mutation:
        if has_identity:
            raise BrpPrerequisite(
                "cannot combine identity verification with --allow-unguarded-mutation"
            )
        client.resolve()
        return {"guard": "explicit-override", "verified": False}

    if args.identity_method is None or args.identity_expected is MISSING:
        raise BrpPrerequisite(
            "mutation requires --identity-method and --identity-expected; "
            "use --allow-unguarded-mutation only for deliberate interactive control"
        )
    if args.identity_method not in READ_ONLY_METHODS:
        raise BrpPrerequisite(
            "identity method must be an allowlisted read-only BRP method"
        )

    client.resolve()
    observed = client.call(args.identity_method, args.identity_params)
    if observed != args.identity_expected:
        raise BrpVerification(
            f"target identity mismatch for {args.identity_method}: "
            f"expected {args.identity_expected!r}, observed {observed!r}"
        )
    return {
        "guard": "identity",
        "method": args.identity_method,
        "verified": True,
    }


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


def receipt(
    client: BrpClient,
    args: argparse.Namespace,
    result: Any,
    identity: dict[str, Any] | None,
) -> dict[str, Any]:
    operation = f"call:{args.method}" if args.command == "call" else args.command
    return {
        "schema_version": 1,
        "skill": "bevy-toolkit",
        "operation": operation,
        "mode": "mutation" if is_mutating(args) else "read-only",
        "status": "success",
        "endpoint": client.last_url,
        "identity": identity,
        "result": result,
    }


def main() -> int:
    args = build_parser().parse_args()
    url = f"http://127.0.0.1:{args.port}" if args.port is not None else args.url
    try:
        client = BrpClient(url, args.timeout)
        identity = verify_mutation_target(client, args)
        result = command_call(client, args)
    except (BrpTimeout, BrpPrerequisite) as error:
        print(f"brp-control: {error}", file=sys.stderr)
        return 3
    except BrpVerification as error:
        print(f"brp-control: {error}", file=sys.stderr)
        return 5
    except (BrpError, OSError) as error:
        print(f"brp-control: {error}", file=sys.stderr)
        return 4
    emit(receipt(client, args, result, identity), args.pretty)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
