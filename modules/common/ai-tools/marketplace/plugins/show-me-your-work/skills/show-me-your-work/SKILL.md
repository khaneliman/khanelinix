---
name: show-me-your-work
description: "Keep a reviewable decision trail for long-running or unattended work: a TSV log with one row per decision (what, why, evidence, result). Local by default; commit it when a reviewer needs the trail to trust the result. Use for /show-me-your-work, autonomous or multi-phase runs, or work a human reviews after stepping away."
---

# Show Me Your Work

Maintain a reviewable decision trail for unattended, multi-phase, or high-risk
runs. Record what was decided, why, and on what evidence so reviewers can
inspect decisions without parsing entire transcripts.

## Log Format

A single TSV file with one row per decision point or checkpoint:

- **ts**: ISO 8601 timestamp.
- **phase**: Active workstream or phase name.
- **decision**: One-line summary of what was chosen or executed.
- **why**: Direct reason explaining the choice or tradeoff.
- **evidence**: File path, commit SHA, PR number, test output, or artifact path.
- **result**: Outcome state (`tests green`, `reverted`, `verified`, `open`).

Header template:
[decision-log-template.tsv](references/decision-log-template.tsv).

## Usage

Log rows using [scripts/log.sh](scripts/log.sh):

```bash
scripts/log.sh <logfile> <phase> <decision> <why> <evidence> <result>
```

Helper automatically stamps ISO timestamps, creates headers, escapes spreadsheet
formula triggers, and strips raw control characters.

## Guidelines

- **Granularity**: Log forks, checkpoints, pivots, reverts, and verification
  gates. Skip trivial edits.
- **Append-only**: Superseded decisions get a new row; never overwrite prior
  history.
- **Location**: Keep local at `decisions.tsv` or `.audit/<task-slug>.tsv`.
  Commit only when a reviewer requires the persistent audit trail.
- **Audit**: Verify log entries against actual transcript actions before
  presenting completion.
