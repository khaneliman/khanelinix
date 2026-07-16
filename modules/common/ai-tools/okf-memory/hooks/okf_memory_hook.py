#!/usr/bin/env python3
"""Start/end lifecycle enforcement for shared OKF memory."""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator

MEMORY_INTENT = (
    re.compile(r"\bremember\s+(?:this|that|my|our|the fact\b)", re.IGNORECASE),
    re.compile(
        r"\b(?:save|persist|record|keep|add)\b.{0,80}"
        r"\b(?:memory|future|preference|lesson|decision)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:memory|preference)\b.{0,40}\b(?:save|persist|record)\b",
        re.IGNORECASE,
    ),
)
DIRECT_MUTATIONS = {
    "apply_patch",
    "code_action",
    "edit",
    "multi_edit",
    "multi_replace_file_content",
    "replace",
    "replace_file_content",
    "write",
    "write_file",
}
SHELL_TOOLS = {"bash", "exec", "exec_command", "run_command", "shell"}
TOOL_THRESHOLD = int(os.environ.get("OKF_MEMORY_TOOL_THRESHOLD", "12"))

START_NUDGE = """[okf-memory] Prior durable memory may apply. Read only relevant project or user OKF scope when this task depends on prior work, saved decisions, recurring issues, or preferences."""

CHECKPOINT = """[okf-memory] End-of-task memory check: would any verified result prevent future research? If yes, invoke okf-memory and write the project or user OKF bundle before any provider-native memory. If no, finish normally. This checkpoint runs once."""


def load_payload() -> dict[str, Any]:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return {}
    return payload if isinstance(payload, dict) else {}


def first_string(payload: dict[str, Any], *names: str) -> str:
    for name in names:
        value = payload.get(name)
        if isinstance(value, str) and value:
            return value
    return ""


def has_memory_intent(prompt: str) -> bool:
    return any(pattern.search(prompt) for pattern in MEMORY_INTENT)


def project_root(payload: dict[str, Any]) -> Path:
    cwd = first_string(payload, "cwd")
    if not cwd:
        workspace = payload.get("workspace")
        if isinstance(workspace, dict):
            cwd = first_string(workspace, "current_dir")
    if not cwd:
        workspaces = payload.get("workspacePaths")
        if isinstance(workspaces, list) and workspaces:
            cwd = workspaces[0] if isinstance(workspaces[0], str) else ""
    root = Path(cwd or Path.cwd()).expanduser()
    try:
        result = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
            capture_output=True,
            check=False,
            text=True,
            timeout=2,
        )
        if result.returncode == 0 and result.stdout.strip():
            return Path(result.stdout.strip())
    except (OSError, subprocess.SubprocessError):
        pass
    return root


def user_bundle() -> Path:
    configured = os.environ.get("OKF_USER_DIR")
    if configured:
        return Path(configured).expanduser()
    data_home = os.environ.get("XDG_DATA_HOME")
    if data_home:
        return Path(data_home).expanduser() / "okf"
    return Path.home() / ".local" / "share" / "okf"


def ensure_user_bundle(bundle: Path) -> None:
    (bundle / "concepts").mkdir(parents=True, exist_ok=True)
    files = {
        bundle / "index.md": """---
type: index
---

# User memory index

Cross-project preferences and reusable lessons live under `concepts/`.
""",
        bundle / "log.md": """---
type: log
---

# User memory log

Chronological record of user-memory updates.
""",
        bundle / "MEMORY.local.md": """---
type: memory
---

No curated user memory yet. Read `index.md` for durable concepts.
""",
    }
    for path, content in files.items():
        if not path.exists():
            path.write_text(content, encoding="utf-8")


def bundles(payload: dict[str, Any]) -> tuple[Path, Path]:
    user = user_bundle()
    ensure_user_bundle(user)
    return user, project_root(payload) / ".okf"


def bundle_digest(paths: tuple[Path, Path]) -> str:
    digest = hashlib.sha256()
    for bundle in paths:
        digest.update(str(bundle).encode())
        if not bundle.is_dir():
            continue
        for path in sorted(bundle.rglob("*.md")):
            if not path.is_file():
                continue
            digest.update(str(path.relative_to(bundle)).encode())
            try:
                digest.update(path.read_bytes())
            except OSError:
                continue
    return digest.hexdigest()


def transcript_path(payload: dict[str, Any]) -> Path | None:
    value = first_string(payload, "transcript_path", "transcriptPath")
    return Path(value).expanduser() if value else None


def is_subagent_source(value: Any) -> bool:
    return isinstance(value, dict) and "subagent" in value


def is_codex_subagent(payload: dict[str, Any]) -> bool:
    if os.environ.get("OKF_MEMORY_INCLUDE_SUBAGENTS") == "1":
        return False
    if is_subagent_source(payload.get("source")):
        return True
    path = transcript_path(payload)
    if path is None:
        return False
    try:
        with path.open(encoding="utf-8") as handle:
            for _, raw_line in zip(range(32), handle):
                try:
                    record = json.loads(raw_line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(record, dict) or record.get("type") != "session_meta":
                    continue
                metadata = record.get("payload")
                return isinstance(metadata, dict) and is_subagent_source(
                    metadata.get("source")
                )
    except OSError:
        pass
    return False


def transcript_snapshot(payload: dict[str, Any]) -> dict[str, int | str]:
    path = transcript_path(payload)
    if path is None:
        return {}
    try:
        stat = path.stat()
    except OSError:
        return {"path": str(path), "offset": 0}
    return {
        "path": str(path),
        "device": stat.st_dev,
        "inode": stat.st_ino,
        "offset": stat.st_size,
    }


def read_jsonl(path: Path, offset: int = 0) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    try:
        with path.open("rb") as handle:
            handle.seek(offset)
            for raw_line in handle:
                try:
                    item = json.loads(raw_line)
                except json.JSONDecodeError:
                    continue
                if isinstance(item, dict):
                    records.append(item)
    except OSError:
        pass
    return records


def records_since_start(
    payload: dict[str, Any], state: dict[str, Any]
) -> tuple[list[dict[str, Any]], dict[str, int | str]]:
    current = transcript_snapshot(payload)
    if not current:
        return [], {}
    previous = state.get("transcript")
    offset = 0
    if (
        isinstance(previous, dict)
        and current.get("path") == previous.get("path")
        and current.get("device") == previous.get("device")
        and current.get("inode") == previous.get("inode")
        and isinstance(previous.get("offset"), int)
        and isinstance(current.get("offset"), int)
        and current["offset"] >= previous["offset"]
    ):
        offset = previous["offset"]
    return read_jsonl(Path(str(current["path"])), offset), current


def content_text(value: Any) -> str:
    if isinstance(value, str):
        return value
    if not isinstance(value, list):
        return ""
    texts = []
    for item in value:
        if not isinstance(item, dict) or item.get("type") == "tool_result":
            continue
        text = item.get("text") or item.get("content")
        if isinstance(text, str):
            texts.append(text)
    return "\n".join(texts)


def user_record(provider: str, record: dict[str, Any]) -> tuple[str, str] | None:
    if provider == "codex" and record.get("type") == "event_msg":
        event = record.get("payload")
        if isinstance(event, dict) and event.get("type") == "user_message":
            prompt = first_string(event, "message")
            marker = json.dumps([record.get("timestamp"), prompt], ensure_ascii=False)
            return prompt, marker
        return None
    if provider == "antigravity" and (
        record.get("type") == "USER_INPUT" or record.get("source") == "USER_EXPLICIT"
    ):
        prompt = content_text(record.get("content"))
        match = re.search(
            r"<USER_REQUEST>\s*(.*?)\s*</USER_REQUEST>", prompt, re.DOTALL
        )
        prompt = match.group(1) if match else prompt
        marker = json.dumps(
            [record.get("step_index"), record.get("created_at"), prompt],
            ensure_ascii=False,
        )
        return prompt, marker
    if provider == "claude" and record.get("type") == "user":
        if record.get("isMeta") is True or record.get("sourceToolUseID"):
            return None
        message = record.get("message")
        if not isinstance(message, dict) or message.get("role") != "user":
            return None
        prompt = content_text(message.get("content"))
        if not prompt:
            return None
        marker = first_string(record, "uuid") or json.dumps(
            [record.get("timestamp"), prompt], ensure_ascii=False
        )
        return prompt, marker
    return None


def latest_user_turn(provider: str, payload: dict[str, Any]) -> tuple[str, str]:
    direct = first_string(payload, "prompt", "user_prompt", "userPrompt")
    if direct:
        return direct, hashlib.sha256(direct.encode()).hexdigest()
    latest: tuple[str, str] | None = None
    path = transcript_path(payload)
    if path is not None:
        for record in read_jsonl(path):
            candidate = user_record(provider, record)
            if candidate is not None:
                latest = candidate
    if latest is not None:
        return latest
    return "", ""


def state_path(payload: dict[str, Any]) -> Path:
    identity = first_string(
        payload,
        "session_id",
        "sessionId",
        "conversationId",
        "transcript_path",
        "transcriptPath",
    )
    if not identity:
        identity = str(project_root(payload))
    key = hashlib.sha256(identity.encode()).hexdigest()[:24]
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    base = Path(runtime) if runtime else Path("/tmp") / f"okf-memory-{os.getuid()}"
    directory = base / "okf-memory-hooks"
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    return directory / f"{key}.json"


def load_state(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return value if isinstance(value, dict) else {}


def save_state(path: Path, state: dict[str, Any]) -> None:
    with tempfile.NamedTemporaryFile(
        dir=path.parent,
        mode="w",
        encoding="utf-8",
        prefix=f".{path.name}.",
        delete=False,
    ) as handle:
        json.dump(state, handle, sort_keys=True)
        temporary = Path(handle.name)
    temporary.replace(path)


@contextmanager
def locked_state(path: Path) -> Iterator[dict[str, Any]]:
    with path.with_suffix(".lock").open("a+", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = load_state(path)
        yield state
        save_state(path, state)


def reset_turn(
    state: dict[str, Any],
    prompt: str,
    marker: str,
    payload: dict[str, Any],
    memory_paths: tuple[Path, Path],
) -> None:
    state.update(
        baseline=bundle_digest(memory_paths),
        explicit_intent=has_memory_intent(prompt),
        stop_reminded=False,
        transcript=transcript_snapshot(payload),
        turn_marker=marker,
    )


def normalize_name(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def targets_okf(value: Any, memory_paths: tuple[Path, Path]) -> bool:
    serialized = json.dumps(value, sort_keys=True, default=str)
    targets = [str(path) for path in memory_paths]
    targets.extend(("/.okf/", ".okf/", "init-bundle.sh"))
    return any(target in serialized for target in targets)


def mutation_targets_okf(
    name: str, arguments: Any, memory_paths: tuple[Path, Path]
) -> bool:
    normalized = normalize_name(name)
    if not targets_okf(arguments, memory_paths):
        return False
    if normalized in DIRECT_MUTATIONS:
        return True
    if normalized not in SHELL_TOOLS:
        return False
    serialized = json.dumps(arguments, sort_keys=True, default=str)
    if "init-bundle.sh" in serialized or "apply_patch" in serialized:
        return True
    target_pattern = (
        "(?:"
        + "|".join(re.escape(str(path)) + "/" for path in memory_paths)
        + r"|(?:\./)?\.okf/)"
    )
    mutation = re.compile(
        rf"(?:\bsed\s+-i\b|\b(?:tee|touch|mkdir|rm)\b)[^;\n]*{target_pattern}"
        rf"|>{1, 2}\s*[\"']?{target_pattern}"
    )
    return mutation.search(serialized) is not None


def parsed_arguments(value: Any) -> Any:
    if not isinstance(value, str):
        return value
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value


def result_succeeded(result: dict[str, Any]) -> bool:
    if result.get("is_error") is True or result.get("success") is False:
        return False
    output = result.get("output")
    if isinstance(output, str) and re.search(r"\b(?:error|failed)\b", output, re.I):
        return False
    return True


def analyze_records(
    provider: str,
    records: list[dict[str, Any]],
    memory_paths: tuple[Path, Path],
) -> tuple[int, bool]:
    calls: set[str] = set()
    targeted_calls: set[str] = set()
    successful_calls: set[str] = set()
    patch_receipt = False
    antigravity_targeted = False
    antigravity_receipt = False

    for record_index, record in enumerate(records):
        message = record.get("message")
        if provider == "claude" and isinstance(message, dict):
            content = message.get("content")
            if isinstance(content, list):
                for item in content:
                    if not isinstance(item, dict):
                        continue
                    if item.get("type") == "tool_use":
                        call_id = first_string(item, "id") or f"claude:{record_index}"
                        calls.add(call_id)
                        if mutation_targets_okf(
                            first_string(item, "name"), item.get("input"), memory_paths
                        ):
                            targeted_calls.add(call_id)
                    elif item.get("type") == "tool_result":
                        call_id = first_string(item, "tool_use_id")
                        if call_id and result_succeeded(item):
                            successful_calls.add(call_id)

        payload = record.get("payload")
        if provider == "codex" and isinstance(payload, dict):
            payload_type = first_string(payload, "type")
            if payload_type in ("custom_tool_call", "function_call"):
                call_id = first_string(payload, "call_id") or f"codex:{record_index}"
                calls.add(call_id)
                arguments = parsed_arguments(
                    payload.get("input", payload.get("arguments"))
                )
                if mutation_targets_okf(
                    first_string(payload, "name"), arguments, memory_paths
                ):
                    targeted_calls.add(call_id)
            elif payload_type in (
                "custom_tool_call_output",
                "function_call_output",
            ):
                call_id = first_string(payload, "call_id")
                if call_id and result_succeeded(payload):
                    successful_calls.add(call_id)
            elif payload_type == "patch_apply_end" and payload.get("success") is True:
                changes = payload.get("changes")
                if isinstance(changes, dict) and targets_okf(
                    list(changes), memory_paths
                ):
                    patch_receipt = True

        if provider == "antigravity":
            tool_calls = record.get("tool_calls")
            if isinstance(tool_calls, list):
                for call_index, item in enumerate(tool_calls):
                    if not isinstance(item, dict):
                        continue
                    call_id = (
                        f"antigravity:{record.get('step_index')}:"
                        f"{call_index}:{first_string(item, 'name')}"
                    )
                    calls.add(call_id)
                    arguments = item.get("args", item.get("arguments"))
                    if mutation_targets_okf(
                        first_string(item, "name"), arguments, memory_paths
                    ):
                        antigravity_targeted = True
            if record.get("type") == "CODE_ACTION" and result_succeeded(record):
                if targets_okf(record, memory_paths):
                    antigravity_receipt = True

    receipt = bool(targeted_calls & successful_calls) or patch_receipt
    if provider == "antigravity":
        receipt = antigravity_targeted and antigravity_receipt
    return len(calls), receipt


def emit_allow(provider: str) -> None:
    print('{"decision":"stop"}' if provider == "antigravity" else "{}")


def emit_context(event_name: str, context: str) -> None:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": event_name,
                    "additionalContext": context,
                }
            }
        )
    )


def emit_no_context(provider: str) -> None:
    print('{"injectSteps":[]}' if provider == "antigravity" else "{}")


def handle_start(provider: str, payload: dict[str, Any]) -> None:
    path = state_path(payload)
    memory_paths = bundles(payload)
    prompt, marker = latest_user_turn(provider, payload)
    if provider != "antigravity":
        reason = normalize_name(
            first_string(
                payload,
                "source",
                "reason",
                "session_start_source",
                "sessionStartSource",
            )
        )
        with locked_state(path) as state:
            if not state or reason in ("startup", "clear"):
                state.clear()
                reset_turn(state, prompt, marker, payload, memory_paths)
        if provider == "codex":
            emit_context(
                first_string(payload, "hook_event_name") or "SessionStart",
                START_NUDGE,
            )
        else:
            emit_no_context(provider)
        return

    with locked_state(path) as state:
        if not state:
            reset_turn(state, prompt, marker, payload, memory_paths)
        elif marker and marker != state.get("turn_marker"):
            reset_turn(state, prompt, marker, payload, memory_paths)
    emit_no_context(provider)


def handle_user_prompt(provider: str, payload: dict[str, Any]) -> None:
    prompt, marker = latest_user_turn(provider, payload)
    path = state_path(payload)
    memory_paths = bundles(payload)
    with locked_state(path) as state:
        reset_turn(state, prompt, marker, payload, memory_paths)
    emit_no_context(provider)


def handle_stop(provider: str, payload: dict[str, Any]) -> None:
    if payload.get("stop_hook_active") is True:
        emit_allow(provider)
        return
    path = state_path(payload)
    memory_paths = bundles(payload)
    should_block = False
    with locked_state(path) as state:
        if not state:
            prompt, marker = latest_user_turn(provider, payload)
            reset_turn(state, prompt, marker, payload, memory_paths)
        records, current_transcript = records_since_start(payload, state)
        tool_count, write_receipt = analyze_records(provider, records, memory_paths)
        current_digest = bundle_digest(memory_paths)
        persisted = write_receipt and current_digest != state.get("baseline")
        needs_checkpoint = bool(
            state.get("explicit_intent") or tool_count >= TOOL_THRESHOLD
        )
        should_block = bool(
            needs_checkpoint and not persisted and not state.get("stop_reminded")
        )
        if should_block:
            state["stop_reminded"] = True
        state["baseline"] = current_digest
        if current_transcript:
            state["transcript"] = current_transcript
    if not should_block:
        emit_allow(provider)
    elif provider == "antigravity":
        print(json.dumps({"decision": "continue", "reason": CHECKPOINT}))
    else:
        print(json.dumps({"decision": "block", "reason": CHECKPOINT}))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("provider", choices=("claude", "codex", "antigravity"))
    parser.add_argument(
        "event",
        choices=("session-start", "pre-invocation", "user-prompt", "stop"),
    )
    args = parser.parse_args()
    payload = load_payload()
    if args.provider == "codex" and is_codex_subagent(payload):
        if args.event == "stop":
            emit_allow(args.provider)
        else:
            emit_no_context(args.provider)
        return
    if args.event in ("session-start", "pre-invocation"):
        handle_start(args.provider, payload)
    elif args.event == "user-prompt":
        handle_user_prompt(args.provider, payload)
    elif args.event == "stop":
        handle_stop(args.provider, payload)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # Hooks must fail open.
        print(f"[okf-memory hook] {exc}", file=sys.stderr)
        print("{}")
