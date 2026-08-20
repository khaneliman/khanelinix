# Review

Use a fresh read-only worker for normal and high-risk plan or diff review.
Prefer a provider different from implementation when capability is comparable.
Opus remains read-only when assigned this phase even though its agent supports
workspace writes.

Request verdict `approved`, `changes_requested`, or `blocked`, then ranked
`critical`, `major`, `minor`, and `suggestion` findings with exact paths,
rationale, and minimal fix.

- Return the verdict, ranked findings, and residual risk to the lifecycle owner.
- Do not fix findings, advance phases, or own the correction verdict.
- Suggestions never expand scope.

For explicit cross-provider review, also read deliberation playbook and
synthesize independent review packets without vote counting.
