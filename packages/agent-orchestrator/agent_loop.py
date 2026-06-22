#!/usr/bin/env python3
"""Agentic task orchestrator with multi-provider fallback.

Distributes work across three independent AI billing plans:
- OpenAI  (Codex Pro)       → codex CLI  : gpt-5.3-codex-spark, gpt-5.5
- Anthropic (Claude Code Max) → claude CLI : opus, sonnet
- Google  (Gemini AI Plus)  → agy CLI    : Gemini 3.1 Pro, Gemini 3.5 Flash,
                                            Claude Opus 4.6, Claude Sonnet 4.6

On rate-limit or provider failure, automatically falls back to the next
provider in the chain, cycling through independent quotas.
"""

from __future__ import annotations

import json
import signal
import subprocess
import sys
from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

STATE_FILE = Path(".agent_state.json")
MAX_RETRIES = 3
MAX_TEST_TIMEOUTS = 2
SUBPROCESS_TIMEOUT = 600  # 10 min default
MAX_OUTPUT_BYTES = 4096  # cap stdout/stderr stored in history


class Step(StrEnum):
    PLAN = "PLAN"
    EXECUTE = "EXECUTE"
    TEST = "TEST"
    REVIEW = "REVIEW"
    DONE = "DONE"


type State = dict[str, Any]

# ---------------------------------------------------------------------------
# Model configuration
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class ModelSpec:
    """A model accessible via a specific CLI provider."""

    provider: str  # "codex" | "claude" | "agy"
    model: str


# Ordered fallback chains per role.  First entry = primary.
# Each chain intentionally spans multiple billing plans so a quota hit
# on one provider cascades to the next without manual intervention.
ROLE_MODELS: dict[str, list[ModelSpec]] = {
    # Planner: single-shot reasoning — decompose user request into tasks
    "planner": [
        ModelSpec("agy", "Gemini 3.1 Pro (High)"),  # Google quota
        ModelSpec("claude", "sonnet"),  # Anthropic quota
        ModelSpec("agy", "Gemini 3.5 Flash (High)"),  # Google quota — fast/cheap
    ],
    # Coder (light): boilerplate, helpers, formatting, simple tests
    "coder_light": [
        ModelSpec("codex", "gpt-5.3-codex-spark"),  # OpenAI quota — fast
        ModelSpec("claude", "sonnet"),  # Anthropic quota
        ModelSpec("agy", "Claude Sonnet 4.6 (Thinking)"),  # Google quota
    ],
    # Coder (heavy): complex logic, concurrency, deep debugging
    "coder_heavy": [
        ModelSpec("codex", "gpt-5.5"),  # OpenAI quota
        ModelSpec("claude", "opus"),  # Anthropic quota — strongest
        ModelSpec("agy", "Claude Opus 4.6 (Thinking)"),  # Google quota
    ],
    # Reviewer: diagnose test / build failures
    "reviewer": [
        ModelSpec("claude", "opus"),  # Anthropic — best at review
        ModelSpec("agy", "Gemini 3.1 Pro (High)"),  # Google quota
        ModelSpec("agy", "Claude Opus 4.6 (Thinking)"),  # Google alternate model
    ],
}

RATE_LIMIT_PATTERNS: list[str] = [
    "rate limit",
    "rate_limit",
    "quota exceeded",
    "too many requests",
    "429",
    "capacity",
    "usage limit",
    "billing",
    "exceeded your",
    "limit reached",
    "throttl",
]

# ---------------------------------------------------------------------------
# CLI command builders
# ---------------------------------------------------------------------------


def _build_reasoning_cmd(spec: ModelSpec, prompt: str) -> list[str]:
    """Build a CLI command for single-shot reasoning (non-agentic)."""
    if spec.provider == "agy":
        return ["agy", "--model", spec.model, "-p", prompt]
    if spec.provider == "claude":
        return ["claude", "-p", prompt, "--model", spec.model]
    msg = f"Provider '{spec.provider}' not supported for reasoning role"
    raise ValueError(msg)


def _build_agentic_cmd(spec: ModelSpec, prompt: str) -> list[str]:
    """Build a CLI command for agentic coding (workspace file edits)."""
    if spec.provider == "codex":
        return [
            "codex",
            "-m",
            spec.model,
            "-s",
            "workspace-write",
            "-a",
            "never",
            "exec",
            prompt,
        ]
    if spec.provider == "claude":
        return [
            "claude",
            "-p",
            prompt,
            "--model",
            spec.model,
            "--allowedTools",
            "Edit,Write,Bash",
            "--dangerously-skip-permissions",
        ]
    if spec.provider == "agy":
        return [
            "agy",
            "--model",
            spec.model,
            "--dangerously-skip-permissions",
            "-p",
            prompt,
        ]
    msg = f"Unknown provider: {spec.provider}"
    raise ValueError(msg)


# ---------------------------------------------------------------------------
# Rate-limit detection & fallback runner
# ---------------------------------------------------------------------------


def _is_rate_limited(error_text: str) -> bool:
    """Heuristic check for rate / usage limit errors."""
    lower = error_text.lower()
    return any(p in lower for p in RATE_LIMIT_PATTERNS)


def _truncate(text: str, max_bytes: int = MAX_OUTPUT_BYTES) -> str:
    """Truncate to *max_bytes*, appending an indicator when trimmed."""
    encoded = text.encode()
    if len(encoded) <= max_bytes:
        return text
    return encoded[:max_bytes].decode(errors="ignore") + "\n…[truncated]"


def _text(value: object) -> str:
    """Render subprocess text fields that may be str, bytes, or None."""
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode(errors="ignore")
    return str(value)


def _exception_text(exc: Exception) -> str:
    """Extract the useful provider error text for fallback logging."""
    if isinstance(exc, subprocess.CalledProcessError):
        return _text(exc.stderr) or _text(exc.stdout) or str(exc)
    if isinstance(exc, subprocess.TimeoutExpired):
        return _text(exc.stderr) or _text(exc.stdout) or str(exc)
    return str(exc)


def _fallback_reason(exc: Exception, error_text: str) -> str:
    """Classify why a provider attempt failed."""
    if isinstance(exc, subprocess.TimeoutExpired):
        return "timeout"
    if isinstance(exc, ValueError):
        return "configuration error"
    if isinstance(exc, OSError):
        return "provider unavailable"
    if _is_rate_limited(error_text):
        return "usage limit"
    return "provider error"


def run_with_fallback(
    role: str,
    prompt: str,
    *,
    agentic: bool = False,
    timeout: int = SUBPROCESS_TIMEOUT,
) -> subprocess.CompletedProcess[str]:
    """Try each model in the role's fallback chain.

    Falls through on rate-limit, timeout, missing CLI, bad config, or other
    provider-level failures.  Raises after every configured provider fails.
    """
    models = ROLE_MODELS.get(role, [])
    if not models:
        msg = f"No models configured for role: {role}"
        raise ValueError(msg)

    build = _build_agentic_cmd if agentic else _build_reasoning_cmd
    last_error: Exception | None = None

    for i, spec in enumerate(models):
        label = f"{spec.provider}:{spec.model}"
        tag = " (fallback)" if i > 0 else ""
        try:
            cmd = build(spec, prompt)
            print(f"  → {label}{tag}")
            return subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
                timeout=timeout,
            )
        except (
            subprocess.CalledProcessError,
            subprocess.TimeoutExpired,
            OSError,
            ValueError,
        ) as e:
            error_text = _exception_text(e)
            reason = _fallback_reason(e, error_text)
            last_error = e
            if i + 1 < len(models):
                detail = f": {_truncate(error_text, 300)}" if error_text else ""
                print(f"  ⚠️  {label} failed ({reason}){detail}")
                print("  Trying next provider…")
                continue
            break

    msg = f"All providers exhausted for role '{role}'"
    raise RuntimeError(msg) from last_error


# ---------------------------------------------------------------------------
# State persistence
# ---------------------------------------------------------------------------


def load_state() -> State:
    """Load or initialize orchestrator state."""
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError) as e:
            print(f"⚠️  Failed to parse {STATE_FILE}, starting fresh: {e}")

    if len(sys.argv) > 1:
        prompt = " ".join(sys.argv[1:])
        return {
            "prompt": prompt,
            "step": Step.PLAN,
            "tasks": [],
            "current_task_idx": 0,
            "history": [],
        }

    print('Usage: agent-orchestrator "[task description]"')
    print("Or run in a directory with an existing .agent_state.json")
    sys.exit(1)


def save_state(state: State) -> None:
    STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------


def _strip_markdown_fences(text: str) -> str:
    """Remove wrapping markdown code fences from LLM output."""
    lines = text.strip().split("\n")
    if lines and lines[0].startswith("```"):
        lines = lines[1:]
    if lines and lines[-1].startswith("```"):
        lines = lines[:-1]
    return "\n".join(lines).strip()


def detect_test_command() -> list[str]:
    """Auto-detect the project's build / test command."""
    # Order matters: prefer Nix-native checks over language-specific runners,
    # since this repo is Nix-first.
    if Path("flake.nix").exists():
        return ["nix", "flake", "check"]
    if Path("Cargo.toml").exists():
        return ["nix", "develop", "--command", "cargo", "test"]
    if Path("package.json").exists():
        return ["nix", "develop", "--command", "npm", "test"]
    if Path("default.nix").exists():
        return ["nix-build", "default.nix", "--no-out-link"]
    return ["echo", "No build/test framework detected — defaulting to success."]


def latest_task_event(
    state: State,
    task_id: int,
    event_types: set[str],
) -> dict[str, Any] | None:
    """Find the newest history event for a task with a matching type."""
    for event in reversed(state["history"]):
        if event.get("task_id") == task_id and event.get("type") in event_types:
            return event
    return None


# ---------------------------------------------------------------------------
# Pipeline steps
# ---------------------------------------------------------------------------


def run_planner(state: State) -> None:
    """PLAN: decompose user request into atomic tasks with role assignments."""
    print("🤖 [Planner] Breaking request into tasks…")

    planner_prompt = (
        "You are the Planner Agent. Analyse the user request and break it into "
        "clear, atomic, sequential tasks.\n"
        "For each task, assign a complexity role:\n"
        "- 'coder_light': simple boilerplate, helpers, formatting, simple tests\n"
        "- 'coder_heavy': complex logic, concurrency, state management, deep debugging\n\n"
        "Output ONLY a raw JSON array — no markdown, no backticks, no extra text.\n"
        "Example:\n"
        '[{"id": 1, "description": "Write helper struct", '
        '"role": "coder_light", "status": "PENDING"}]\n\n'
        f"User request: {state['prompt']}"
    )

    try:
        result = run_with_fallback("planner", planner_prompt)
        raw = _strip_markdown_fences(result.stdout)
        tasks: list[dict[str, Any]] = json.loads(raw)
        state["tasks"] = tasks
        state["step"] = Step.EXECUTE
        state["current_task_idx"] = 0
        print(f"✅ Planned {len(tasks)} tasks:")
        for t in tasks:
            print(f"   [{t.get('role', '?')}] {t['description']}")
    except (
        subprocess.CalledProcessError,
        subprocess.TimeoutExpired,
        json.JSONDecodeError,
        KeyError,
        RuntimeError,
    ) as e:
        print(f"❌ Planning failed: {e}. Using single-task fallback.")
        state["tasks"] = [
            {
                "id": 1,
                "description": f"Implement user request: {state['prompt']}",
                "role": "coder_heavy",
                "status": "PENDING",
            }
        ]
        state["step"] = Step.EXECUTE
        state["current_task_idx"] = 0

    save_state(state)


def run_coder(state: State) -> None:
    """EXECUTE: agentic coding to implement one task."""
    idx = state["current_task_idx"]
    task = state["tasks"][idx]
    role = task.get("role", "coder_heavy")
    total = len(state["tasks"])
    print(f"💻 [Coder] Task {task['id']}/{total}  role={role}")
    print(f"   {task['description'][:200]}")

    # Inject prior failure context when retrying.
    context = ""
    event = latest_task_event(
        state,
        task["id"],
        {"test_failure", "test_timeout", "coder_error"},
    )
    if event is not None:
        if event.get("type") in {"test_failure", "test_timeout"}:
            context = (
                f"\nPrevious attempt failed:\n{event.get('error', '')}\nFix this error."
            )
        else:
            context = (
                f"\nPrevious coder execution failed:\n{event.get('error', '')}\n"
                "Try a different implementation approach."
            )

    prompt = (
        f"Task: {task['description']}\n{context}\n"
        "Implement changes locally in the workspace. "
        "When complete, output a brief confirmation."
    )

    try:
        result = run_with_fallback(role, prompt, agentic=True)
        state["history"].append(
            {
                "task_id": task["id"],
                "type": "execution",
                "role": role,
                "stdout": _truncate(result.stdout),
                "stderr": _truncate(result.stderr),
            }
        )
        state["step"] = Step.TEST
        print("✅ Coder done.")
    except (
        subprocess.CalledProcessError,
        subprocess.TimeoutExpired,
        RuntimeError,
    ) as e:
        error_msg = (
            (e.stderr or e.stdout or str(e))
            if isinstance(e, subprocess.CalledProcessError)
            else str(e)
        )
        print(f"❌ Coder failed: {_truncate(error_msg, 500)}")
        state["history"].append(
            {
                "task_id": task["id"],
                "type": "coder_error",
                "error": _truncate(error_msg),
            }
        )
        if not _check_retry_limit(task, state):
            state["step"] = Step.REVIEW

    save_state(state)


def _check_retry_limit(task: dict[str, Any], state: State) -> bool:
    """Bump retry counter. Return True if limit exceeded (task marked FAILED)."""
    task.setdefault("retries", 0)
    task["retries"] += 1
    if task["retries"] > MAX_RETRIES:
        print(f"❌ Task {task['id']} exceeded {MAX_RETRIES} retries — skipping.")
        task["status"] = "FAILED"
        idx = state["current_task_idx"]
        if idx + 1 < len(state["tasks"]):
            state["current_task_idx"] += 1
            state["step"] = Step.EXECUTE
        else:
            state["step"] = Step.DONE
        return True
    return False


def _check_test_timeout_limit(task: dict[str, Any], state: State) -> bool:
    """Bump test timeout counter without consuming coder retry slots."""
    task.setdefault("test_timeouts", 0)
    task["test_timeouts"] += 1
    if task["test_timeouts"] > MAX_TEST_TIMEOUTS:
        print(
            f"❌ Task {task['id']} exceeded {MAX_TEST_TIMEOUTS} test timeouts — skipping."
        )
        task["status"] = "FAILED"
        idx = state["current_task_idx"]
        if idx + 1 < len(state["tasks"]):
            state["current_task_idx"] += 1
            state["step"] = Step.EXECUTE
        else:
            state["step"] = Step.DONE
        return True
    return False


def run_tester(state: State) -> None:
    """TEST: run project build / test to verify coder output."""
    idx = state["current_task_idx"]
    task = state["tasks"][idx]
    print("🧪 [Tester] Verifying…")

    test_cmd = detect_test_command()
    print(f"   $ {' '.join(test_cmd)}")

    try:
        result = subprocess.run(
            test_cmd,
            capture_output=True,
            text=True,
            timeout=SUBPROCESS_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        print(f"❌ Test timed out ({SUBPROCESS_TIMEOUT}s)")
        state["history"].append(
            {
                "task_id": task["id"],
                "type": "test_timeout",
                "error": f"Test timed out after {SUBPROCESS_TIMEOUT}s",
            }
        )
        if not _check_test_timeout_limit(task, state):
            state["step"] = Step.REVIEW
        save_state(state)
        return

    if result.returncode == 0:
        print("✅ Tests passed.")
        task["status"] = "COMPLETED"
        state["history"].append(
            {
                "task_id": task["id"],
                "type": "test_success",
                "stdout": _truncate(result.stdout),
            }
        )
        if idx + 1 < len(state["tasks"]):
            state["current_task_idx"] += 1
            state["step"] = Step.EXECUTE
        else:
            state["step"] = Step.DONE
    else:
        print("❌ Tests failed.")
        error_log = result.stderr.strip() or result.stdout
        state["history"].append(
            {
                "task_id": task["id"],
                "type": "test_failure",
                "error": _truncate(error_log),
            }
        )
        if _check_retry_limit(task, state):
            pass
        elif task.get("role") == "coder_light":
            print("🔄 Escalating coder_light → coder_heavy for retry.")
            task["role"] = "coder_heavy"
            state["step"] = Step.EXECUTE
        else:
            state["step"] = Step.REVIEW

    save_state(state)


def run_reviewer(state: State) -> None:
    """REVIEW: strong reasoning model diagnoses build / test failure."""
    idx = state["current_task_idx"]
    task = state["tasks"][idx]
    print("🔍 [Reviewer] Diagnosing failure…")

    event = latest_task_event(
        state,
        task["id"],
        {"test_failure", "test_timeout", "coder_error"},
    )
    error_log = event.get("error", "") if event is not None else ""

    reviewer_prompt = (
        "You are the Reviewer/Debugger Agent. The coder failed.\n"
        f"Original Task: {task['description']}\n"
        f"Error Log:\n{error_log}\n\n"
        "Provide a precise, step-by-step diagnostic and fix. Keep it concise."
    )

    try:
        result = run_with_fallback("reviewer", reviewer_prompt)
        advice = result.stdout.strip()
        print("\n─── Reviewer Advice ───")
        print(_truncate(advice, 2000))
        print("───────────────────────\n")

        # Append advice but cap description to prevent token ballooning
        combined = f"{task['description']}\n\n[Reviewer Advice]:\n{advice}"
        task["description"] = _truncate(combined, MAX_OUTPUT_BYTES)
        task["role"] = "coder_heavy"
        state["step"] = Step.EXECUTE
    except (
        subprocess.CalledProcessError,
        subprocess.TimeoutExpired,
        RuntimeError,
    ) as e:
        print(f"❌ Reviewer failed: {e}. Retrying directly with coder_heavy.")
        task["role"] = "coder_heavy"
        state["step"] = Step.EXECUTE

    save_state(state)


# ---------------------------------------------------------------------------
# Signal handling
# ---------------------------------------------------------------------------

_current_state: State | None = None


def _handle_signal(signum: int, _frame: Any) -> None:
    """Save state on interrupt so the run can be resumed."""
    name = signal.Signals(signum).name
    print(f"\n⚠️  {name} received — saving state for resumption…")
    if _current_state is not None:
        save_state(_current_state)
    sys.exit(128 + signum)


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------


def main() -> None:
    global _current_state  # noqa: PLW0603

    signal.signal(signal.SIGINT, _handle_signal)
    signal.signal(signal.SIGTERM, _handle_signal)

    state = load_state()
    _current_state = state

    while state["step"] != Step.DONE:
        match state["step"]:
            case Step.PLAN:
                run_planner(state)
            case Step.EXECUTE:
                run_coder(state)
            case Step.TEST:
                run_tester(state)
            case Step.REVIEW:
                run_reviewer(state)

    # Accurate summary — don't claim success when tasks failed
    completed = sum(1 for t in state["tasks"] if t.get("status") == "COMPLETED")
    failed = sum(1 for t in state["tasks"] if t.get("status") == "FAILED")
    total = len(state["tasks"])

    if failed:
        print(
            f"⚠️  [Orchestrator] Done: {completed}/{total} succeeded, {failed} failed."
        )
    else:
        print(f"🎉 [Orchestrator] All {total} tasks completed successfully!")

    if STATE_FILE.exists():
        STATE_FILE.unlink()

    _current_state = None


if __name__ == "__main__":
    main()
