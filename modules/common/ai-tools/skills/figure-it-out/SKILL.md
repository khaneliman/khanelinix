---
name: figure-it-out
description: "Design and run an auditable playbook when no narrower one fits: scaled rigor, a hypothesis loop, and a logged decision trail. Use for /figure-it-out, 'figure it out', a large migration, or unattended work a human reviews later. Use software-engineering for the architecture plan itself."
---

# Figure It Out

When no playbook matches, design one. First deliverable is a phase sequence that
scales rigor, runs the scientific method, and leaves a decision trail a human can
audit after stepping away. Bias toward rigor because wrong work costs more.

Do not reinvent a playbook you already have. Route a focused single-unit task to
its matching playbook: bug fix, performance, feature, visual parity, evaluation,
or multi-phase plan. Use this skill for the large or cross-cutting version of
one, such as a migration across many call sites, an ambitious multi-part change,
or work the user reviews after stepping away. The rigor and the audit trail are
the point.

Open a todolist with the phases below as items.

## Phase A: Frame

Do not start the run until you can state:

- The definition of done as a falsifiable predicate (the prove-it-works
  principle in `engineering-principles`). "Done well" has to be checkable.
- Scope, quantified: rough units and effort, plus the blockers grounding
  surfaced. Raise blockers before spending hours, not after fifty doomed
  commits.
- The rigor level, biased high. One-way doors and a wide breakage surface earn
  more rigor. Reversible low-stakes steps earn less. Rigor means gates and
  artifacts, not "try harder".

Present the framing and tradeoffs before committing to a long run. Reversible
work proceeds without asking, but a multi-hour run earns one checkpoint.

## Phase B: Design the workflow

Decompose the task into atomic, independently landable units. Before writes,
use `git-toolkit` to plan the stack and its rollback boundaries. Sequence the
riskiest unknown first. Build scaffold and verification before features.

- Build the verification harness before the work. Capture the baseline from the
  pre-change state so each check reads as old value against new value.
- For one-way-door design decisions, run `architect`, which runs `arena`, with
  diverse, isolated, opinionated candidates and a read-only judge on a different
  model family. Skip it for mechanical work whose shape is already concrete. A
  second arena over a settled design is over-engineering (the laziness-protocol
  principle in `engineering-principles`).
- Decide what fans out. Parallelize only across genuine seams. Give each
  parallel worker its own worktree or branch so no two workers share mutable
  state. Do not over-fan.
- Write the designed phase list down. The human reviews that list.
- When the run spans sessions or risks compaction, persist the designed phase
  list and the findings through `planning-with-files`.

Then put the design into motion. Add its steps to the todolist as concrete
items, after the Phase C entry and before Phase D. Run each step under the Phase
C loop discipline. Weave the Phase D log through the steps, one row as each step
lands, instead of saving the whole trail for the end.

## Phase C: Run the loop

This skill owns the program lifecycle, hypotheses, and audit trail.
`verified-slice` stays a unit method and does not own program lifecycle,
architecture, or audit trail.

State the hypothesis and predicate. Then run each planned unit through the
`verified-slice` method in `engineering-principles`. It handles baseline,
implementation, proportional verification, review, correction, and exact
candidate preparation. With `local-commit`, commit the candidate, then confirm
occurrence. Otherwise, hand off the exact patch and stop. Start the next unit
only after a confirmed occurrence and durable rollback boundary.

Inspect the real artifact, never a self-report. Pair delegated work with a judge
and audit its artifact. Use VERIFIED, NOT_VERIFIED, or INCONCLUSIVE. An
inconclusive result does not pass.

## Phase D: Keep the audit trail

Log the run through `show-me-your-work`: one canonical TSV with a row per
decision and per unit, evidence as links. Work run under this skill is usually
ambitious enough to commit the trail so the reviewer reads it in the pull
request. Commit the trail when confidence has to be shown. Prefer evidence
produced by committed scripts so a reviewer can re-run it. The trail plus the
diff is what lets the human come back and trust the work.

## Phase E: Verify and hand back

Check the whole against the Phase A predicate on the real product, not only the
harness. Encode any recurring correction as a gate, a lint rule, a check, or a
script so the win cannot silently regress (the encode-lessons-in-structure
principle in `engineering-principles`).

**Reply:** the playbook you designed, the rigor level and why, the
decision-trail path, what is verified against the predicate, and what is still
open.
