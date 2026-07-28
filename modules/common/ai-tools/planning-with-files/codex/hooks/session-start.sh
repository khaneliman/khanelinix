#!/usr/bin/env sh
# planning-with-files: SessionStart hook for Codex
# Runs session catchup. Adapter adds a concise nudge after clear or compaction;
# the first UserPromptSubmit supplies it on startup or resume.

# issue #195: per-invocation opt-out for one-shot/CI sessions (e.g. codex exec)
# that share a cwd with a plan but never opted into it.
[ "${PLANNING_DISABLED:-}" = "1" ] && exit 0

CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME:-}/.config}"
SKILL_DIR="${PWF_SKILL_DIR:-${CONFIG_HOME}/codex/skills/planning-with-files}"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"

if [ -n "$PYTHON_BIN" ] && [ -f "$SKILL_DIR/scripts/session-catchup.py" ]; then
    "$PYTHON_BIN" "$SKILL_DIR/scripts/session-catchup.py" "$(pwd)"
fi

exit 0
