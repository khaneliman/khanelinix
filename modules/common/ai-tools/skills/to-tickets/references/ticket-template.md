# Ticket Template

Use this structure for each ticket. Keep fields concrete and omit no required
field.

```markdown
# <Ticket ID>: <Ticket title>

- Status: <ready only after prerequisites are verified complete and choices are
  settled | blocked otherwise>
- Source: <resolvable local path or URL>, spec ID <stable ID>, revision
  <integer>
- Revalidation: <required if this ticket is affected by a newer source revision,
  otherwise None>
- Objective: <one independently verifiable outcome>
- Non-goals: <explicit exclusions>
- Blockers: <ticket IDs, or None>
- Unresolved choices: <material choices and what they block, or None>
- Write scope hints: <paths or symbols to verify before implementation>
- Parallelization: <serialized order, or isolated worktree plus named
  integration owner and order>

## Acceptance

- <observable result>

## Constraints and interfaces

- <invariant, compatibility requirement, or interface contract>

## Verification and expected evidence

- Check: `<exact command or check>` Evidence: <expected output, artifact, or
  behavior>

## Fresh-session instruction

Use `$engineering-workflow` (or <existing project owner>) to implement and
verify this ticket. Re-read the source spec and repository guidance first.
Before implementation writes, compare the source identity and revision with this
ticket. If either differs, revalidate affected requirements, reconcile
acceptance criteria, and record the source revision and result in this ticket.
The revalidated source governs over stale ticket text. Unresolved differences
block implementation. Recheck prerequisite completion and write ownership. This
ticket fits one fresh session. Continue execution only when that next action is
separately authorized; the named owner handles its lifecycle.
```
