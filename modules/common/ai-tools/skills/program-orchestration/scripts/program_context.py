"""Render bounded provider context from validated program-control state."""

from __future__ import annotations

import json
import os
import stat
import subprocess
import sys
from pathlib import Path
from typing import TYPE_CHECKING, Any, NoReturn, TextIO

# Most sessions have no active program. Import the state engine only after an
# active pointer exists, so the neutral path stays cheap.
if TYPE_CHECKING:
    import program_state

MAX_INPUT_BYTES = 1024 * 1024
MAX_OUTPUT_BYTES = 4096
MAX_UNITS = 8
PREFIX = "Untrusted program state data\n"
TRUNCATION_WARNING = "bounded-context-truncated"
INVALID_STATE_WARNING = "active-program-state-invalid"
EVENT_NAMES = {
    "session-start": "SessionStart",
    "user-prompt": "UserPromptSubmit",
}
PROVIDERS = {"claude", "codex"}


class InputError(ValueError):
    """Report rejected provider hook input."""


class ManagedPathError(ValueError):
    """Report an unusable managed program-state path."""


def strict_payload_loads(raw: str) -> Any:
    def reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                raise InputError(f"provider hook input contains duplicate key: {key}")
            result[key] = value
        return result

    def reject_constant(value: str) -> NoReturn:
        raise InputError(f"provider hook input contains non-finite number: {value}")

    try:
        return json.loads(
            raw,
            object_pairs_hook=reject_duplicate_keys,
            parse_constant=reject_constant,
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise InputError(f"provider hook input is invalid JSON: {error}") from error


def load_payload(stream: TextIO) -> dict[str, Any] | None:
    raw = stream.read(MAX_INPUT_BYTES + 1)
    if not raw.strip() or len(raw.encode("utf-8")) > MAX_INPUT_BYTES:
        return None
    try:
        payload = strict_payload_loads(raw)
    except InputError:
        return None
    return payload if isinstance(payload, dict) else None


def cwd_from_payload(payload: dict[str, Any]) -> Path | None:
    cwd = payload.get("cwd")
    if isinstance(cwd, str) and cwd and "\x00" not in cwd:
        return Path(cwd)
    return None


def repository_root(cwd: Path) -> Path | None:
    try:
        resolved_cwd = cwd.expanduser().resolve(strict=True)
    except OSError:
        return None
    if not resolved_cwd.is_dir():
        return None

    try:
        result = subprocess.run(
            ["git", "-C", str(resolved_cwd), "rev-parse", "--show-toplevel"],
            check=False,
            capture_output=True,
            text=True,
            timeout=3,
        )
    except FileNotFoundError:
        print(
            "program-context: git is not on PATH; no program context", file=sys.stderr
        )
        return None
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None

    root_text = result.stdout.rstrip("\r\n")
    if not root_text or "\x00" in root_text:
        return None
    try:
        root = Path(root_text).resolve(strict=True)
    except OSError:
        return None
    if not root.is_dir() or not resolved_cwd.is_relative_to(root):
        return None
    return root


def lstat_managed_path(path: Path) -> os.stat_result | None:
    try:
        return path.lstat()
    except FileNotFoundError:
        return None
    except OSError as error:
        raise ManagedPathError(
            f"cannot inspect managed path {path}: {error}"
        ) from error


def managed_directory_exists(path: Path) -> bool:
    metadata = lstat_managed_path(path)
    if metadata is None:
        return False
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        raise ManagedPathError(f"managed path must be a non-symlink directory: {path}")
    return True


def active_pointer_exists(root: Path) -> bool:
    if not managed_directory_exists(root / ".agent"):
        return False

    programs = root / ".agent" / "programs"
    if not managed_directory_exists(programs):
        return False
    return lstat_managed_path(programs / "active.json") is not None


def active_grant_capabilities(state: dict[str, Any], now: str) -> list[str]:
    import program_state

    return sorted(
        {
            grant["capability"]
            for grant in state["grants"].values()
            if program_state.grant_is_active(grant, now)
        }
    )


def active_leases(state: dict[str, Any]) -> list[dict[str, Any]]:
    return sorted(
        (lease for lease in state["leases"].values() if lease["status"] == "active"),
        key=lambda lease: lease["unit_id"],
    )


def dependencies_landed(state: dict[str, Any], unit: dict[str, Any]) -> bool:
    import program_state

    return all(
        program_state.dependency_is_landed(state, dependency)
        for dependency in unit["dependencies"]
    )


def next_controller_action(state: dict[str, Any], now: str) -> str:
    import program_state

    status = state["status"]
    if status in {"completed", "aborted"}:
        return "none-terminal"

    leases = active_leases(state)
    if any(
        program_state.parse_utc(lease["expires_at"]) <= program_state.parse_utc(now)
        for lease in leases
    ):
        return "review-expired-lease-reconciliation"
    if leases:
        return "review-active-lease"
    if status == "paused":
        return "review-paused-program"

    units = list(state["units"].values())
    dispatchable = any(
        unit["status"] == "ready"
        and dependencies_landed(state, unit)
        and program_state.requirements_are_covered(state, unit, now)
        for unit in units
    )
    if dispatchable:
        return "verify-host-permission-before-dispatch"
    if any(unit["status"] == "ready" for unit in units):
        return "review-readiness-or-grants"
    if any(unit["status"] == "blocked" for unit in units):
        return "review-blocked-unit"
    if len(units) >= 2 and all(
        unit["status"] == "cancelled"
        or (
            unit["status"] == "landed"
            and program_state.receipt_is_valid(state, unit["receipt_id"])
        )
        for unit in units
    ):
        return "review-program-completion"
    if not units:
        return "review-program-definition"
    if any(unit["status"] == "planned" for unit in units):
        return "review-dependencies-and-grants"
    return "review-program-state"


def provider_wrapper(event: str, context: str) -> dict[str, Any]:
    return {
        "hookSpecificOutput": {
            "hookEventName": EVENT_NAMES[event],
            "additionalContext": context,
        }
    }


def encode_wrapper(event: str, context: str) -> bytes:
    return (
        json.dumps(
            provider_wrapper(event, context),
            ensure_ascii=False,
            allow_nan=False,
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


def encode_context(data: dict[str, Any]) -> str:
    return PREFIX + json.dumps(
        data,
        ensure_ascii=False,
        allow_nan=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def fits(event: str, data: dict[str, Any], *, reserve_warning: bool) -> bool:
    candidate = dict(data)
    if reserve_warning:
        candidate["warning"] = TRUNCATION_WARNING
    return len(encode_wrapper(event, encode_context(candidate))) <= MAX_OUTPUT_BYTES


def unit_candidates(
    state: dict[str, Any],
) -> tuple[list[tuple[dict[str, Any], dict[str, Any]]], bool]:
    eligible = sorted(
        (
            unit
            for unit in state["units"].values()
            if unit["status"] in {"leased", "ready"}
        ),
        key=lambda unit: (0 if unit["status"] == "leased" else 1, unit["unit_id"]),
    )
    candidates: list[tuple[dict[str, Any], dict[str, Any]]] = []
    truncated = len(eligible) > MAX_UNITS
    for unit in eligible[:MAX_UNITS]:
        summary: dict[str, Any] = {
            "dependencies": [],
            "id": unit["unit_id"],
            "owner": unit["owner"],
            "state": unit["status"],
        }
        if unit["status"] == "leased":
            lease = state["leases"][unit["active_lease_id"]]
            summary["lease"] = {
                "expires_at": lease["expires_at"],
                "holder": lease["holder"],
                "scopes": [],
            }
        candidates.append((summary, unit))
    return candidates, truncated


def context_data(
    loaded: program_state.LoadedProgram,
    event: str,
    *,
    now: str | None = None,
) -> dict[str, Any]:
    import program_state

    state = loaded.state
    at = now or program_state.utc_now()
    program_state.require_utc(at, "context time")
    candidates, candidates_truncated = unit_candidates(state)
    truncated = candidates_truncated

    data: dict[str, Any] = {
        "active_grant_capabilities": active_grant_capabilities(state, at),
        "next_controller_action": next_controller_action(state, at),
        "program": {
            "id": state["program_id"],
            "journal_head": state["head"],
            "status": state["status"],
        },
        "units": [],
    }

    included: list[tuple[dict[str, Any], dict[str, Any]]] = []
    for summary, unit in candidates:
        data["units"].append(summary)
        if not fits(event, data, reserve_warning=True):
            data["units"].pop()
            truncated = True
            break
        included.append((summary, unit))
    if len(included) < len(candidates):
        truncated = True

    for summary, unit in included:
        for dependency in unit["dependencies"]:
            item = {
                "id": dependency,
                "state": state["units"][dependency]["status"],
            }
            summary["dependencies"].append(item)
            if not fits(event, data, reserve_warning=True):
                summary["dependencies"].pop()
                truncated = True
                break

        lease_summary = summary.get("lease")
        if lease_summary is None:
            continue
        lease = state["leases"][unit["active_lease_id"]]
        for scope in lease["resource_scopes"]:
            lease_summary["scopes"].append(scope)
            if not fits(event, data, reserve_warning=True):
                lease_summary["scopes"].pop()
                truncated = True
                break

    if truncated:
        data["warning"] = TRUNCATION_WARNING
    if not fits(event, data, reserve_warning=False):
        raise program_state.ProgramError("program context exceeds provider limit")
    return data


def invalid_state_output(event: str) -> bytes:
    data = {
        "next_controller_action": "validate-program-state",
        "warning": INVALID_STATE_WARNING,
    }
    return encode_wrapper(event, encode_context(data))


def report_invalid_state(event: str) -> bytes:
    print(
        "[program-orchestration hook] active program state is invalid",
        file=sys.stderr,
    )
    return invalid_state_output(event)


def validate_snapshot_component(loaded: program_state.LoadedProgram) -> None:
    import program_state

    if program_state.lstat_path(loaded.snapshot_path) is not None:
        program_state.validate_regular_file(
            loaded.snapshot_path,
            "snapshot",
            maximum_bytes=program_state.MAX_SNAPSHOT_BYTES,
        )


def render_hook(
    provider: str,
    event: str,
    payload: dict[str, Any],
    *,
    now: str | None = None,
) -> bytes | None:
    if provider not in PROVIDERS or event not in EVENT_NAMES:
        return None
    cwd = cwd_from_payload(payload)
    if cwd is None:
        return None
    root = repository_root(cwd)
    if root is None:
        return None

    try:
        if not active_pointer_exists(root):
            return None
    except ManagedPathError:
        return report_invalid_state(event)

    import program_state

    try:
        loaded = program_state.load_program(root)
        validate_snapshot_component(loaded)
        data = context_data(loaded, event, now=now)
    except program_state.ProgramError:
        return report_invalid_state(event)
    return encode_wrapper(event, encode_context(data))


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 2 or args[0] not in PROVIDERS or args[1] not in EVENT_NAMES:
        print("[program-orchestration hook] invalid provider adapter", file=sys.stderr)
        return 0
    try:
        payload = load_payload(sys.stdin)
        if payload is None or cwd_from_payload(payload) is None:
            print(
                "[program-orchestration hook] invalid provider input", file=sys.stderr
            )
            return 0
        output = render_hook(args[0], args[1], payload)
        if output is not None:
            sys.stdout.buffer.write(output)
    except Exception:  # noqa: BLE001 - provider hooks must fail open
        print("[program-orchestration hook] context rendering failed", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
