#!/usr/bin/env python3
"""Remind a fan-out orchestrator to keep its worker lanes filled.

Advisory only: never gates a tool, and fails open.
"""

from __future__ import annotations

import fcntl
import hashlib
import json
import os
import re
import sys
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path
from typing import Any

PROVIDER = "claude"
# Two lanes in flight at once is what makes a session a fan-out run. Users ask
# for fan-out in prose, so this counts launches instead of parsing prompts.
ACTIVE_PEAK = 2
# Tool calls without a dispatch or finish, while slots sit empty, before the
# drift reminder. Raise it if integration-heavy runs see the reminder too
# early; lower it if serial stretches still run long.
DRIFT_CALLS = 20
# T3 wakes either with a bare notice or with the result inline after an
# optional title and a status such as [completed] or [failed].
T3_WAKE = re.compile(
    r"Delegated task (\S+)(?: \(.*?\))? (?:\[\w+\]|reached a terminal state)"
)
# Prompts the harness submits on its own; none of them is a new user request.
NOTIFICATION = re.compile(
    r"^\s*(?:\[SYSTEM NOTIFICATION|<task-notification>|Stop hook feedback:|"
    + T3_WAKE.pattern
    + ")"
)
TASK_BLOCK = re.compile(r"<task-notification>.*?</task-notification>", re.DOTALL)
TASK_ID = re.compile(r"<task-id>\s*([^<\s]+)\s*</task-id>")
# A worker that parks its own background job reports in, then reports again
# under the same ID when that job finishes.
INTERIM = "waiting on its own background work"
DISPATCH_TOOLS = {"Agent", "mcp__t3-code__delegate_task"}
T3_STATUS_TOOLS = {"mcp__t3-code__task_status", "mcp__t3-code__task_cancel"}
# background_tasks types that are worker lanes; shells and monitors are not.
WORKER_TASK_TYPES = {"subagent", "workflow", "teammate", "cloud session", "MCP task"}
MAX_LABELS = 8
MAX_LABEL_CHARS = 80


def load_payload(stream: Any) -> dict[str, Any] | None:
    try:
        payload = json.load(stream)
    except (json.JSONDecodeError, OSError, TypeError, ValueError):
        return None
    return payload if isinstance(payload, dict) else None


def state_path(session_id: str) -> Path:
    key = hashlib.sha256(session_id.encode()).hexdigest()[:24]
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    base = Path(runtime) if runtime else Path("/tmp") / f"worker-lanes-{os.getuid()}"
    return base / "worker-lanes" / f"{key}.json"


@contextmanager
def session_state(path: Path) -> Iterator[dict[str, Any]]:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    with path.with_suffix(".lock").open("a+", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            loaded = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            loaded = {}
        state: dict[str, Any] = loaded if isinstance(loaded, dict) else {}
        if not isinstance(state.get("lanes"), dict):
            state["lanes"] = {}
        before = json.dumps(state, sort_keys=True)
        yield state
        if json.dumps(state, sort_keys=True) != before:
            with tempfile.NamedTemporaryFile(
                "w", dir=path.parent, encoding="utf-8", prefix=".", delete=False
            ) as handle:
                json.dump(state, handle, sort_keys=True)
            Path(handle.name).replace(path)


def short(text: object) -> str:
    line = " ".join(text.split()) if isinstance(text, str) else ""
    if len(line) > MAX_LABEL_CHARS:
        return line[: MAX_LABEL_CHARS - 3] + "..."
    return line or "worker"


def lane_list(labels: list[str]) -> str:
    if not labels:
        return "none"
    hidden = len(labels) - MAX_LABELS
    return "; ".join(labels[:MAX_LABELS]) + (
        f"; and {hidden} more" if hidden > 0 else ""
    )


def labels(lanes: dict[str, Any]) -> list[str]:
    return [str(lane.get("label")) for lane in lanes.values() if isinstance(lane, dict)]


def t3_field(value: object, name: str) -> str | None:
    # MCP results arrive as structured content or as JSON inside text blocks.
    if isinstance(value, dict):
        found = value.get(name)
        if isinstance(found, str) and found:
            return found
        value = list(value.values())
    if isinstance(value, list):
        return next((found for item in value if (found := t3_field(item, name))), None)
    if isinstance(value, str) and value.lstrip().startswith(("{", "[")):
        try:
            return t3_field(json.loads(value), name)
        except json.JSONDecodeError:
            return None
    return None


def launched_lane(
    tool: object, arguments: dict[str, Any], response: object
) -> tuple[str, dict[str, str]] | None:
    if tool == "Agent":
        if not isinstance(response, dict) or response.get("status") != "async_launched":
            return None
        agent_id = response.get("agentId")
        if not isinstance(agent_id, str) or not agent_id:
            return None
        label = short(arguments.get("description") or response.get("description"))
        return agent_id, {"kind": "agent", "label": label}
    if arguments.get("mode") == "wait":
        return None
    task_id = t3_field(response, "taskId")
    if task_id is None:
        return None
    label = short(arguments.get("title") or arguments.get("task"))
    # task_status and task_cancel need the T3 ID. Native agent IDs stay out of
    # reminders because the harness treats them as internal metadata.
    return task_id, {"kind": "t3", "label": f"{label} (task {task_id})"}


def finished_ids(prompt: str, lanes: dict[str, Any]) -> set[str]:
    ids = {
        task_id
        for block in TASK_BLOCK.findall(prompt)
        if INTERIM not in block
        for task_id in TASK_ID.findall(block)
    }
    ids.update(T3_WAKE.findall(prompt))
    return ids & set(lanes)


def emit(event: str, context: str) -> dict[str, Any]:
    return {
        "hookSpecificOutput": {"hookEventName": event, "additionalContext": context}
    }


def finish(state: dict[str, Any], ids: set[str]) -> list[str]:
    finished = [
        str(state["lanes"].pop(lane_id).get("label")) for lane_id in sorted(ids)
    ]
    if finished:
        state["unrefilled"] = int(state.get("unrefilled", 0)) + len(finished)
        state["quiet"] = 0
        state["drift_reminded"] = False
    return finished


def active(state: dict[str, Any]) -> bool:
    return int(state.get("peak", 0)) >= ACTIVE_PEAK


def on_post_tool(
    state: dict[str, Any], payload: dict[str, Any]
) -> dict[str, Any] | None:
    tool = payload.get("tool_name")
    tool_input = payload.get("tool_input")
    arguments = tool_input if isinstance(tool_input, dict) else {}
    response = payload.get("tool_response")
    lanes = state["lanes"]
    if tool in DISPATCH_TOOLS:
        lane = launched_lane(tool, arguments, response)
        if lane is not None:
            lanes[lane[0]] = lane[1]
            state["peak"] = max(int(state.get("peak", 0)), len(lanes))
            state.update(unrefilled=0, quiet=0, drift_reminded=False)
        return None
    if tool in T3_STATUS_TOOLS:
        task_id = arguments.get("taskId")
        terminal = tool.endswith("task_cancel") or (
            t3_field(response, "workState") == "result_available"
        )
        if not terminal or not isinstance(task_id, str) or task_id not in lanes:
            return None
        return finish_reminder("PostToolUse", state, finish(state, {task_id}))
    if not active(state) or state.get("drift_reminded") or len(lanes) >= state["peak"]:
        return None
    state["quiet"] = int(state.get("quiet", 0)) + 1
    if state["quiet"] < DRIFT_CALLS:
        return None
    state["drift_reminded"] = True
    return emit(
        "PostToolUse",
        f"[worker-lanes] {len(lanes)} of {state['peak']} worker lanes are in "
        + f"flight and nothing has been dispatched for {state['quiet']} tool "
        + "calls. If independent slices are ready, dispatch them instead of "
        + "doing them serially here; otherwise continue.",
    )


def on_user_prompt(state: dict[str, Any], prompt: str) -> dict[str, Any] | None:
    if not NOTIFICATION.match(prompt):
        # A new request after the lanes drain starts a new run.
        if not state["lanes"]:
            state.clear()
            state["lanes"] = {}
        return None
    finished = finish(state, finished_ids(prompt, state["lanes"]))
    return finish_reminder("UserPromptSubmit", state, finished)


def finish_reminder(
    event: str, state: dict[str, Any], finished: list[str]
) -> dict[str, Any] | None:
    if not finished or not active(state):
        return None
    return emit(
        event,
        f"[worker-lanes] Finished: {lane_list(finished)}. Still in flight: "
        + f"{lane_list(labels(state['lanes']))}. Refill the freed slot from "
        + "the ready queue as soon as the active workflow allows (for an "
        + "isolated writer, after its worktree closes), then integrate this "
        + "result while the other workers run.",
    )


def on_stop(state: dict[str, Any], payload: dict[str, Any]) -> dict[str, Any] | None:
    lanes = state["lanes"]
    tasks = payload.get("background_tasks")
    running: list[str] = []
    if isinstance(tasks, list):
        workers = {
            str(task.get("id")): short(task.get("description"))
            for task in tasks
            if isinstance(task, dict) and task.get("type") in WORKER_TASK_TYPES
        }
        # The harness list is authoritative for native lanes, so a lane missing
        # from it finished even if its notification never reached this hook.
        # T3 tasks are not in the list.
        finish(
            state,
            {
                lane_id
                for lane_id, lane in lanes.items()
                if isinstance(lane, dict)
                and lane.get("kind") == "agent"
                and lane_id not in workers
            },
        )
        running = [label for task_id, label in workers.items() if task_id not in lanes]
    running += labels(lanes)
    if (
        not active(state)
        or payload.get("stop_hook_active") is True
        or int(state.get("unrefilled", 0)) <= 0
        or running
    ):
        return None
    state["unrefilled"] = 0
    return emit(
        "Stop",
        "[worker-lanes] No worker lane is in flight. If ready slices remain, "
        + "dispatch them now rather than waiting. If the run is complete, stop "
        + "here without another summary.",
    )


def handle(provider: str, event: str, payload: dict[str, Any]) -> dict[str, Any] | None:
    if provider != PROVIDER or payload.get("agent_id") is not None:
        return None
    session_id = payload.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        return None
    path = state_path(session_id)
    # Sessions that never launch a worker never get state.
    if not path.exists() and not (
        event == "post-tool" and payload.get("tool_name") in DISPATCH_TOOLS
    ):
        return None
    with session_state(path) as state:
        if event == "post-tool":
            return on_post_tool(state, payload)
        if event == "user-prompt":
            prompt = payload.get("prompt")
            return on_user_prompt(state, prompt) if isinstance(prompt, str) else None
        if event == "stop":
            return on_stop(state, payload)
    return None


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 2:
        return 0
    payload = load_payload(sys.stdin)
    if payload is None:
        return 0
    try:
        output = handle(args[0], args[1], payload)
    except Exception as error:  # Hooks must fail open.  # noqa: BLE001
        print(f"[worker-lanes hook] {error}", file=sys.stderr)
        return 0
    if output is not None:
        json.dump(output, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
