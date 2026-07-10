---
name: planning-with-files
description: "Persistent file-based planning for complex or long-running work. Use when asked to plan, organize, research, or execute work requiring multiple phases or roughly 5+ tool calls. Keeps task_plan.md, findings.md, and progress.md recoverable across sessions and compaction."
user-invocable: true
allowed-tools: "Read Write Edit Bash Glob Grep"
hooks:
  UserPromptSubmit:
    - hooks:
        - type: command
          command: "SH=\"${CLAUDE_SKILL_DIR}/scripts/inject-plan.sh\"; [ -f \"$SH\" ] || SH=$(ls \"$HOME/.claude/skills/planning-with-files/scripts/inject-plan.sh\" \"$HOME/.claude/plugins/marketplaces/planning-with-files/scripts/inject-plan.sh\" 2>/dev/null | head -1); [ -n \"$SH\" ] && [ -f \"$SH\" ] && sh \"$SH\" --context=userprompt; exit 0"
  Stop:
    - hooks:
        - type: command
          command: "SH=\"${CLAUDE_SKILL_DIR}/scripts/gate-stop.sh\"; [ -f \"$SH\" ] || SH=$(ls \"$HOME/.claude/skills/planning-with-files/scripts/gate-stop.sh\" \"$HOME/.claude/plugins/marketplaces/planning-with-files/scripts/gate-stop.sh\" 2>/dev/null | head -1); [ -n \"$SH\" ] && [ -f \"$SH\" ] && sh \"$SH\" 2>/dev/null; exit 0"
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

## References

- Detailed workflow and security notes: [reference.md](reference.md)
- Example plans and logs: [examples.md](examples.md)
- Templates: [templates/task_plan.md](templates/task_plan.md),
  [templates/findings.md](templates/findings.md),
  [templates/progress.md](templates/progress.md)
