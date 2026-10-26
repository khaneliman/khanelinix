#!/usr/bin/env python3
"""Remind a fan-out orchestrator to keep its worker lanes filled.

One provider-neutral state machine. Each harness adapter turns its hook
payloads into an Observation and renders reminders in its own output format.
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
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# Two lanes in flight at once is what makes a session a fan-out run. Users ask
# for fan-out in prose, so this counts launches instead of parsing prompts.
ACTIVE_PEAK = 2
# Work steps without a dispatch or finish, while slots sit empty, before the
# drift reminder. Raise it if integration-heavy runs see the reminder too
# early; lower it if serial stretches still run long.
DRIFT_STEPS = 20
MAX_LABELS = 8
MAX_LABEL_CHARS = 80

# T3 Code tools reach a harness through MCP, and each harness spells MCP tool
# names its own way.
T3_DELEGATE = re.compile(r"t3[-_]code\W*_*delegate_task$")
T3_STATUS = re.compile(r"t3[-_]code\W*_*task_(status|cancel)$")
# T3 wakes either with a bare notice or with the result inline after an
# optional title and a status such as [completed] or [failed].
T3_WAKE = re.compile(
    r"Delegated task (\S+)(?: \(.*?\))? (?:\[\w+\]|reached a terminal state)"
)

CLAUDE_NOTIFICATION = re.compile(
    r"^\s*(?:\[SYSTEM NOTIFICATION|<task-notification>|Stop hook feedback:|"
    + T3_WAKE.pattern
    + ")"
)
CLAUDE_TASK_BLOCK = re.compile(r"<task-notification>.*?</task-notification>", re.DOTALL)
CLAUDE_TASK_ID = re.compile(r"<task-id>\s*([^<\s]+)\s*</task-id>")
# A worker that parks its own background job reports in, then reports again
# under the same ID when that job finishes.
CLAUDE_INTERIM = "waiting on its own background work"
# background_tasks types that are worker lanes; shells and monitors are not.
CLAUDE_WORKER_TYPES = {
    "subagent",
    "workflow",
    "teammate",
    "cloud session",
    "MCP task",
}

AGY_SPAWN = "invoke_subagent"
# The spawn result step type changed across releases, so match its text.
AGY_SPAWNED = "Created the following subagent"
AGY_CHILD_ID = re.compile(r'"conversationId"\s*:\s*"([^"]+)"')
AGY_REPORT = re.compile(
    r"\[Message\][^\n]*?\bsender=(\S+)|Subagent (\S+) has gone idle"
)


# Hooks see collab tools bare or with a namespace glued on, such as
# "spawn_agent" and "multi_agent_v1wait_agent".
CODEX_SPAWN = re.compile(r"(?:^|multi_agent_v\d+_*)spawn(?:_agent)?$")
CODEX_WAIT = re.compile(r"(?:^|multi_agent_v\d+_*)wait(?:_agent)?$")
CODEX_CLOSE = re.compile(r"(?:^|multi_agent_v\d+_*)close_agent$")
CODEX_DONE = {"completed", "errored", "interrupted", "shutdown"}
CODEX_NOTIFICATION = re.compile(
    r"<subagent_notification>.*?</subagent_notification>", re.DOTALL
)
CODEX_NOTIFIED_ID = re.compile(r'"agent_(?:path|id)"\s*:\s*"([^"]+)"')


@dataclass
class Observation:
    """One hook call, normalized across harnesses."""

    launched: dict[str, dict[str, Any]] = field(default_factory=dict)
    finished: set[str] = field(default_factory=set)
    # A launch came after the last finish, so freed slots were refilled. One
    # transcript read can hold launches and reports in either order.
    refilled: bool = False
    # Work steps taken without a dispatch, for the drift reminder.
    steps: int = 0
    # A new user request is the latest event, after any launch or finish.
    user_request: bool = False
    # This event's output reaches the orchestrator as context. Finishes seen
    # on other events wait for the next one that does.
    deliver: bool = True
    stop: bool = False
    # False when the harness already continued this stop, or ended the turn for
    # a reason a reminder must not override, such as a user cancel.
    may_continue: bool = True
    # Lanes of `native_kind` the harness itself reports as in flight. When
    # present it is authoritative: a missing lane has finished.
    running: dict[str, str] | None = None
    native_kind: str = ""
    # The harness reports background work still running without naming it.
    busy: bool = False


@dataclass
class Adapter:
    # Whether this call can launch a lane, so a session without state needs one.
    starts: Callable[[str, dict[str, Any]], bool]
    observe: Callable[[str, dict[str, Any], dict[str, Any]], Observation | None]
    render: Callable[[str, str | None], dict[str, Any] | None]


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


def labels(lanes: dict[str, Any], *, wakes: bool | None = None) -> list[str]:
    return [
        str(lane.get("label"))
        for lane in lanes.values()
        if isinstance(lane, dict)
        and (wakes is None or bool(lane.get("wakes", True)) == wakes)
    ]


def lane(kind: str, label: str, *, wakes: bool = True) -> dict[str, Any]:
    return {"kind": kind, "label": label, "wakes": wakes}


def field_value(value: object, name: str) -> str | None:
    # MCP results arrive as structured content or as JSON inside text blocks.
    if isinstance(value, dict):
        found = value.get(name)
        if isinstance(found, str) and found:
            return found
        value = list(value.values())
    if isinstance(value, list):
        return next(
            (found for item in value if (found := field_value(item, name))), None
        )
    if isinstance(value, str) and value.lstrip().startswith(("{", "[")):
        try:
            return field_value(json.loads(value), name)
        except json.JSONDecodeError:
            return None
    return None


def t3_tool(
    obs: Observation, tool: str, arguments: dict[str, Any], response: object
) -> bool:
    """Record T3 delegated-task launches and terminal reads for any harness."""
    if T3_DELEGATE.search(tool):
        task_id = field_value(response, "taskId")
        if arguments.get("mode") != "wait" and task_id:
            label = short(arguments.get("title") or arguments.get("task"))
            # task_status and task_cancel need the T3 ID, so it stays visible.
            obs.launched[task_id] = lane("t3", f"{label} (task {task_id})")
            obs.refilled = True
        return True
    match = T3_STATUS.search(tool)
    if match is None:
        return False
    task_id = arguments.get("taskId")
    terminal = match.group(1) == "cancel" or (
        field_value(response, "workState") == "result_available"
    )
    if terminal and isinstance(task_id, str):
        obs.finished.add(task_id)
    return True


def claude_starts(event: str, payload: dict[str, Any]) -> bool:
    tool = str(payload.get("tool_name") or "")
    return (
        event == "post-tool"
        and payload.get("agent_id") is None
        and (tool == "Agent" or bool(T3_DELEGATE.search(tool)))
    )


def claude(
    event: str, payload: dict[str, Any], _state: dict[str, Any]
) -> Observation | None:
    if payload.get("agent_id") is not None:
        return None
    obs = Observation(native_kind="agent")
    if event == "post-tool":
        tool = str(payload.get("tool_name") or "")
        tool_input = payload.get("tool_input")
        arguments = tool_input if isinstance(tool_input, dict) else {}
        response = payload.get("tool_response")
        if tool == "Agent":
            if (
                isinstance(response, dict)
                and response.get("status") == "async_launched"
            ):
                agent_id = response.get("agentId")
                if isinstance(agent_id, str) and agent_id:
                    # Native agent IDs stay out of reminders because the
                    # harness treats them as internal metadata.
                    obs.launched[agent_id] = lane(
                        "agent",
                        short(
                            arguments.get("description") or response.get("description")
                        ),
                    )
                    obs.refilled = True
        elif not t3_tool(obs, tool, arguments, response):
            obs.steps = 1
        return obs
    if event == "user-prompt":
        prompt = payload.get("prompt")
        if not isinstance(prompt, str):
            return None
        if not CLAUDE_NOTIFICATION.match(prompt):
            obs.user_request = True
            return obs
        obs.finished = {
            task_id
            for block in CLAUDE_TASK_BLOCK.findall(prompt)
            if CLAUDE_INTERIM not in block
            for task_id in CLAUDE_TASK_ID.findall(block)
        }
        obs.finished.update(T3_WAKE.findall(prompt))
        return obs
    if event == "stop":
        obs.stop = True
        obs.may_continue = payload.get("stop_hook_active") is not True
        tasks = payload.get("background_tasks")
        if isinstance(tasks, list):
            obs.running = {
                str(task.get("id")): short(task.get("description"))
                for task in tasks
                if isinstance(task, dict) and task.get("type") in CLAUDE_WORKER_TYPES
            }
        return obs
    return None


def claude_render(event: str, text: str | None) -> dict[str, Any] | None:
    if text is None:
        return None
    name = {
        "post-tool": "PostToolUse",
        "user-prompt": "UserPromptSubmit",
        "stop": "Stop",
    }
    return {
        "hookSpecificOutput": {"hookEventName": name[event], "additionalContext": text}
    }


def agy_starts(event: str, payload: dict[str, Any]) -> bool:
    call = payload.get("toolCall")
    return (
        event == "post-tool"
        and isinstance(call, dict)
        and call.get("name") == AGY_SPAWN
    )


def agy_spawn_labels(call: dict[str, Any]) -> list[str]:
    args = call.get("args")
    if not isinstance(args, dict):
        return []
    # Older releases batch children under "Subagents"; newer ones spawn one.
    batch = args.get("Subagents")
    specs = batch if isinstance(batch, list) else [args]
    return [
        short(spec.get("Role") or spec.get("Prompt"))
        for spec in specs
        if isinstance(spec, dict)
    ]


def agy_transcript(
    payload: dict[str, Any], state: dict[str, Any], obs: Observation
) -> None:
    """Fold transcript steps written since the last call into the observation."""
    path = payload.get("transcriptPath")
    if not isinstance(path, str) or not path:
        return
    try:
        info = os.stat(path)
    except OSError:
        return
    identity = [path, info.st_dev, info.st_ino]
    offset = state.get("transcript_offset")
    pending = state.get("spawn_labels")
    # A replaced or truncated transcript starts over from its beginning.
    if (
        state.get("transcript") != identity
        or not isinstance(offset, int)
        or offset > info.st_size
    ):
        offset, pending = 0, []
    pending = pending if isinstance(pending, list) else []
    try:
        with open(path, "rb") as handle:
            handle.seek(offset)
            for raw in handle:
                # A partial last line belongs to a step still being written.
                if not raw.endswith(b"\n"):
                    break
                offset += len(raw)
                try:
                    step = json.loads(raw)
                except ValueError:
                    continue
                if isinstance(step, dict):
                    pending = agy_step(step, pending, obs)
    except OSError:
        return
    state.update(transcript=identity, transcript_offset=offset, spawn_labels=pending)


def agy_step(step: dict[str, Any], pending: list[str], obs: Observation) -> list[str]:
    kind = step.get("type")
    content = step.get("content")
    text = content if isinstance(content, str) else ""
    if kind == "USER_INPUT" and step.get("source") == "USER_EXPLICIT":
        obs.user_request = True
    elif step.get("source") == "MODEL" and AGY_SPAWNED in text:
        for child_id in AGY_CHILD_ID.findall(text):
            label = pending.pop(0) if pending else "subagent"
            obs.launched[child_id] = lane("agy", label)
            obs.refilled = True
            obs.user_request = False
    elif kind == "SYSTEM_MESSAGE":
        for sender, idle in AGY_REPORT.findall(text):
            obs.finished.add(sender or idle)
            obs.refilled = False
            obs.user_request = False
    if kind == "PLANNER_RESPONSE":
        # Labels wait only for this step's spawn results, so a failed spawn
        # cannot shift later labels.
        pending = []
    calls = step.get("tool_calls")
    for call in calls if isinstance(calls, list) else []:
        if not isinstance(call, dict):
            continue
        args = call.get("args")
        args = args if isinstance(args, dict) else {}
        if call.get("name") == AGY_SPAWN:
            pending = pending + agy_spawn_labels(call)
        elif call.get("name") == "manage_subagents" and args.get("Action") == "kill":
            ids = args.get("ConversationIds")
            if isinstance(ids, list):
                obs.finished.update(i for i in ids if isinstance(i, str))
                obs.refilled = False
    return pending


def agy(
    event: str, payload: dict[str, Any], state: dict[str, Any]
) -> Observation | None:
    obs = Observation(native_kind="agy")
    if event == "post-tool":
        # PostToolUse carries no tool result, so lanes come from the transcript,
        # and its output cannot reach the model. Recording a start offset saves
        # state so the next PreInvocation reads the spawn results.
        state.setdefault("transcript_offset", 0)
        obs.deliver = False
        return obs
    agy_transcript(payload, state, obs)
    if event == "pre-invocation":
        # Each model call after the first in a turn follows tool work.
        number = payload.get("invocationNum")
        obs.steps = 1 if isinstance(number, int) and number > 0 else 0
        return obs
    if event == "stop":
        obs.stop = True
        # Cancels, errors, and limits must end the turn as the harness decided.
        obs.may_continue = payload.get("terminationReason") == "NO_TOOL_CALL"
        if payload.get("fullyIdle") is True:
            obs.running = {}
        else:
            obs.busy = True
        return obs
    return None


def agy_render(event: str, text: str | None) -> dict[str, Any] | None:
    if event == "stop":
        if text is None:
            return {"decision": "stop"}
        return {"decision": "continue", "reason": text}
    if event == "pre-invocation":
        return {"injectSteps": [{"ephemeralMessage": text}] if text else []}
    return {}


def codex_starts(event: str, payload: dict[str, Any]) -> bool:
    tool = str(payload.get("tool_name") or "")
    return (
        event == "post-tool"
        and payload.get("agent_id") is None
        and bool(CODEX_SPAWN.search(tool) or T3_DELEGATE.search(tool))
    )


def codex(
    event: str, payload: dict[str, Any], _state: dict[str, Any]
) -> Observation | None:
    obs = Observation()
    if event == "subagent-stop":
        # Fires in the parent session for the finished child. Its output would
        # steer the child, so the parent hears about it on a later event.
        child = payload.get("agent_id")
        if isinstance(child, str) and child:
            obs.finished.add(child)
        obs.deliver = False
        return obs
    # The child's own hook calls share the parent's session_id.
    if payload.get("agent_id") is not None:
        return None
    if event == "post-tool":
        tool = str(payload.get("tool_name") or "")
        tool_input = payload.get("tool_input")
        arguments = tool_input if isinstance(tool_input, dict) else {}
        response = payload.get("tool_response")
        if CODEX_SPAWN.search(tool):
            child = field_value(response, "agent_id")
            if child:
                nickname = field_value(response, "nickname")
                message = arguments.get("message")
                summary = short(f"{nickname}: {message}" if nickname else message)
                # Codex never starts a parent turn when a native child finishes,
                # and waiting on it needs the agent ID.
                obs.launched[child] = lane(
                    "codex", f"{summary} (agent {child})", wakes=False
                )
                obs.refilled = True
        elif CODEX_WAIT.search(tool):
            statuses = response
            if isinstance(statuses, str):
                try:
                    statuses = json.loads(statuses)
                except json.JSONDecodeError:
                    statuses = None
            status = statuses.get("status") if isinstance(statuses, dict) else None
            if isinstance(status, dict):
                obs.finished.update(
                    child
                    for child, result in status.items()
                    if (isinstance(result, dict) and result.keys() & CODEX_DONE)
                    or result == "not_found"
                )
        elif CODEX_CLOSE.search(tool):
            target = arguments.get("target")
            if isinstance(target, str):
                obs.finished.add(target)
        elif not t3_tool(obs, tool, arguments, response):
            obs.steps = 1
        return obs
    if event == "user-prompt":
        prompt = payload.get("prompt")
        if not isinstance(prompt, str):
            return None
        notices = CODEX_NOTIFICATION.findall(prompt)
        wakes = T3_WAKE.findall(prompt)
        if not notices and not wakes:
            obs.user_request = True
            return obs
        obs.finished.update(wakes)
        for notice in notices:
            obs.finished.update(CODEX_NOTIFIED_ID.findall(notice))
        return obs
    if event == "stop":
        obs.stop = True
        obs.may_continue = payload.get("stop_hook_active") is not True
        return obs
    return None


def codex_render(event: str, text: str | None) -> dict[str, Any] | None:
    if text is None or event == "subagent-stop":
        return None
    if event == "stop":
        return {"decision": "block", "reason": text}
    name = {"post-tool": "PostToolUse", "user-prompt": "UserPromptSubmit"}
    return {
        "hookSpecificOutput": {"hookEventName": name[event], "additionalContext": text}
    }


ADAPTERS = {
    "claude": Adapter(claude_starts, claude, claude_render),
    "antigravity": Adapter(agy_starts, agy, agy_render),
    "codex": Adapter(codex_starts, codex, codex_render),
}


def active(state: dict[str, Any]) -> bool:
    return int(state.get("peak", 0)) >= ACTIVE_PEAK


def apply(state: dict[str, Any], obs: Observation) -> str | None:
    lanes = state["lanes"]

    def take_finished() -> list[str]:
        gone = set(obs.finished)
        if obs.running is not None:
            gone |= {
                lane_id
                for lane_id, record in lanes.items()
                if isinstance(record, dict)
                and record.get("kind") == obs.native_kind
                and lane_id not in obs.running
            }
        return [
            str(lanes.pop(lane_id).get("label"))
            for lane_id in sorted(gone & set(lanes))
        ]

    # Lanes that already finished leave before new ones count toward the peak.
    # A lane that launched and finished within one read leaves after it counts.
    finished = take_finished()
    if obs.launched:
        lanes.update(obs.launched)
        state["peak"] = max(int(state.get("peak", 0)), len(lanes))
        finished += take_finished()
    if obs.refilled:
        state["unrefilled"] = 0
        state.pop("unannounced", None)
    elif finished:
        state["unrefilled"] = int(state.get("unrefilled", 0)) + len(finished)
        state["unannounced"] = list(state.get("unannounced", [])) + finished
    if finished or obs.launched:
        state.update(quiet=0, drift_reminded=False)
    if obs.user_request and not lanes:
        # A new request after the lanes drain starts a new run.
        for key in ("peak", "unrefilled", "unannounced", "quiet", "drift_reminded"):
            state.pop(key, None)
    if obs.stop:
        return stop_reminder(state, obs)
    if obs.deliver and state.get("unannounced"):
        finished = state.pop("unannounced")
        if not active(state):
            return None
        return (
            f"[worker-lanes] Finished: {lane_list(finished)}. Still in flight: "
            + f"{lane_list(labels(lanes))}. Refill the freed slot from the ready "
            + "queue as soon as the active workflow allows (for an isolated "
            + "writer, after its worktree closes), then integrate this result "
            + "while the other workers run."
        )
    if (
        not obs.steps
        or obs.launched
        or not active(state)
        or state.get("drift_reminded")
        or len(lanes) >= state["peak"]
    ):
        return None
    state["quiet"] = int(state.get("quiet", 0)) + obs.steps
    if state["quiet"] < DRIFT_STEPS:
        return None
    state["drift_reminded"] = True
    return (
        f"[worker-lanes] {len(lanes)} of {state['peak']} worker lanes are in "
        + f"flight and nothing has been dispatched for {state['quiet']} steps. "
        + "If independent slices are ready, dispatch them instead of doing "
        + "them serially here; otherwise continue."
    )


def stop_reminder(state: dict[str, Any], obs: Observation) -> str | None:
    if not obs.may_continue:
        return None
    lanes = state["lanes"]
    # Some harnesses never start a new turn when a worker finishes, so ending
    # the turn strands those lanes until the user asks.
    sleeping = labels(lanes, wakes=False)
    if sleeping:
        return (
            "[worker-lanes] Still running, and their completion will not wake "
            + f"you: {lane_list(sleeping)}. Wait on them and integrate their "
            + "results instead of ending the turn, unless the user asked you to "
            + "stop."
        )
    running = labels(lanes) + [
        label for task_id, label in (obs.running or {}).items() if task_id not in lanes
    ]
    if not active(state) or int(state.get("unrefilled", 0)) <= 0 or running or obs.busy:
        return None
    state["unrefilled"] = 0
    state.pop("unannounced", None)
    return (
        "[worker-lanes] No worker lane is in flight. If ready slices remain, "
        + "dispatch them now rather than waiting. If the run is complete, "
        + "confirm that in one line instead of repeating your report."
    )


def session_key(payload: dict[str, Any]) -> str | None:
    for name in ("session_id", "conversationId"):
        value = payload.get(name)
        if isinstance(value, str) and value:
            return value
    return None


def handle(provider: str, event: str, payload: dict[str, Any]) -> dict[str, Any] | None:
    adapter = ADAPTERS.get(provider)
    if adapter is None:
        return None
    key = session_key(payload)
    if key is None:
        return adapter.render(event, None)
    path = state_path(key)
    # Sessions that never launch a worker never get state.
    if not path.exists() and not adapter.starts(event, payload):
        return adapter.render(event, None)
    with session_state(path) as state:
        obs = adapter.observe(event, payload, state)
        return adapter.render(event, None if obs is None else apply(state, obs))


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 2:
        return 0
    provider, event = args
    payload = load_payload(sys.stdin)
    try:
        output = handle(provider, event, payload or {})
    except Exception as error:  # Hooks must fail open.  # noqa: BLE001
        print(f"[worker-lanes hook] {error}", file=sys.stderr)
        adapter = ADAPTERS.get(provider)
        output = adapter.render(event, None) if adapter else None
    if output is not None:
        json.dump(output, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
