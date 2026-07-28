# Review

Use a fresh read-only worker for normal and high-risk plan or diff review.
Prefer a provider different from implementation when capability is comparable.
Opus remains read-only when assigned this phase even though its agent supports
workspace writes.

Request verdict `approved`, `changes_requested`, or `blocked`, then ranked
`critical`, `major`, `minor`, and `suggestion` findings with exact paths,
rationale, and minimal fix.

- Fix critical and major findings when within scope; stop only when resolution
  needs user choice or material expansion.
- Fix low-risk minor findings; report the rest.
- Suggestions never expand scope.
- Apply one bounded correction batch, rerun affected validation, then use one
  fresh re-review maximum.

For explicit cross-provider review, also read deliberation playbook and
synthesize independent review packets without vote counting.
