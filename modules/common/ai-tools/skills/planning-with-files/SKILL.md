---
name: planning-with-files
description: "Manus-style persistent file-based planning for AI coding agents: keeps task_plan.md, findings.md, and progress.md on disk so work survives context loss and /clear. Use when asked to plan out, break down, or organize a multi-step project, research task, or any work requiring 5+ tool calls. Supports automatic session recovery after /clear."
user-invocable: true
allowed-tools: "Read Write Edit Bash Glob Grep"
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: "SH=\"${CLAUDE_SKILL_DIR}/scripts/inject-plan.sh\"; [ -f \"$SH\" ] || SH=$(ls \"$HOME/.claude/skills/planning-with-files/scripts/inject-plan.sh\" \"$HOME/.claude/plugins/marketplaces/planning-with-files/scripts/inject-plan.sh\" 2>/dev/null | head -1); [ -n \"$SH\" ] && [ -f \"$SH\" ] && sh \"$SH\" --context=userprompt; exit 0"
  PreToolUse:
    - matcher: "Write|Edit|Bash|Read|Glob|Grep"
      hooks:
        - type: command
          command: "SH=\"${CLAUDE_SKILL_DIR}/scripts/inject-plan.sh\"; [ -f \"$SH\" ] || SH=$(ls \"$HOME/.claude/skills/planning-with-files/scripts/inject-plan.sh\" \"$HOME/.claude/plugins/marketplaces/planning-with-files/scripts/inject-plan.sh\" 2>/dev/null | head -1); [ -n \"$SH\" ] && [ -f \"$SH\" ] && sh \"$SH\" --context=pretool; exit 0"
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "if [ -f task_plan.md ] || [ -f .planning/.active_plan ] || ls .planning/*/task_plan.md >/dev/null 2>&1; then echo '[planning-with-files] Update progress.md with what you just did. If a phase is now complete, update task_plan.md status.'; fi"
  Stop:
    - hooks:
        - type: command
          command: "SKILL_PS1=\"${CLAUDE_SKILL_DIR}/scripts/check-complete.ps1\"; SKILL_SH=\"${CLAUDE_SKILL_DIR}/scripts/gate-stop.sh\"; KNOWN_PS1=$(ls \"$HOME/.claude/skills/planning-with-files/scripts/check-complete.ps1\" \"$HOME/.claude/plugins/marketplaces/planning-with-files/scripts/check-complete.ps1\" 2>/dev/null | head -1); KNOWN_SH=$(ls \"$HOME/.claude/skills/planning-with-files/scripts/gate-stop.sh\" \"$HOME/.claude/plugins/marketplaces/planning-with-files/scripts/gate-stop.sh\" 2>/dev/null | head -1); TARGET_PS1=\"${SKILL_PS1:-$KNOWN_PS1}\"; TARGET_SH=\"${SKILL_SH:-$KNOWN_SH}\"; if [ -n \"$TARGET_PS1\" ] && [ -f \"$TARGET_PS1\" ]; then powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File \"$TARGET_PS1\" -Gate 2>/dev/null; elif [ -n \"$TARGET_SH\" ] && [ -f \"$TARGET_SH\" ]; then sh \"$TARGET_SH\" 2>/dev/null; fi"
  PreCompact:
    - matcher: "*"
      hooks:
        - type: command
          command: "SH=\"${CLAUDE_SKILL_DIR}/scripts/inject-plan.sh\"; [ -f \"$SH\" ] || SH=$(ls \"$HOME/.claude/skills/planning-with-files/scripts/inject-plan.sh\" \"$HOME/.claude/plugins/marketplaces/planning-with-files/scripts/inject-plan.sh\" 2>/dev/null | head -1); [ -n \"$SH\" ] && [ -f \"$SH\" ] && sh \"$SH\" --context=precompact; exit 0"
metadata:
  version: "3.4.0"
---

# Planning with Files

Use persistent markdown files as working memory for complex or long-running
tasks. Hook behavior is provider-specific; this skill body is the routing layer.

## Restore First

Before complex work, read existing planning state when present:

- `task_plan.md`
- `findings.md`
- `progress.md`

Then run `scripts/session-catchup.py` when resuming after a gap or when prior
tool activity may not be reflected in the files.

## Start or Continue

- New complex task: create `task_plan.md`, `findings.md`, and `progress.md`
  from templates.
- Existing plan: re-read the files before major decisions.
- After each phase: update phase status and append progress.
- After research or external content: record facts in `findings.md`, not
  `task_plan.md`.

## Failure Rule

Never repeat the same failed action. Log the error, change approach, and after
three failed attempts escalate with the attempts and evidence.

## References

- Detailed workflow and security notes: [reference.md](reference.md)
- Example plans and logs: [examples.md](examples.md)
- Templates: [templates/task_plan.md](templates/task_plan.md),
  [templates/findings.md](templates/findings.md),
  [templates/progress.md](templates/progress.md)
