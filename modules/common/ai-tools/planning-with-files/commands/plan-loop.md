---
description: "Run a planning-aware cadence with Claude Code's /loop. Default tick checks plan status, runs check-complete, nudges progress.md update if stalled. Available since v2.38.0."
disable-model-invocation: true
allowed-tools: "Read Bash"
---

Run a planning-aware cadence on top of Claude Code's `/loop` primitive.

Steps:

1. Parse args:
   - First arg matching `^\d+[smhd]$` is the interval (default `10m`).
   - Remaining args are an optional task prompt.
2. Resolve the active plan as in `/plan-attest`.
3. Compose the loop prompt:
   - If user passed a task prompt: use it verbatim.
   - Else: use the default planning tick prompt:
     ```
     Read task_plan.md and progress.md. Run scripts/check-complete.sh to see remaining phases.
     If no progress.md entry has been added since the last loop tick, write one summarizing the current state.
     If a phase finished, update its Status: line in task_plan.md.
     Continue the next phase if work remains.
     ```
4. Invoke `/loop <interval> <prompt>`.
5. Confirm to the user: print the interval, the active plan ID, and remind that
   bare `/loop` invocation alone (without args) runs Claude Code's built-in
   maintenance prompt — `/plan-loop` differs by always grounding the tick in the
   planning files.

If `task_plan.md` does not exist, refuse and direct user to run `/plan` first.

Why this exists:

`/loop` runs prompts on cron without any plan-state contract. `/plan-loop`
injects a plan-aware default so the recurring tick always re-reads the planning
files first, runs the completion check, and writes a progress entry. Users get
"babysit my plan" UX without writing a custom loop prompt.

Notes:

- `/plan-loop` composes with `/loop`; it does not replace it.
  `/loop 5m "anything"` still works.
- For "babysit until plan is done" semantics: combine `/plan-loop 10m` (cadence)
  with `/plan-goal` (termination criterion). The loop runs every 10 minutes; the
  goal stops the loop when the plan is complete.
- The default tick prompt is intentionally short so it stays within
  compaction-safe length.
