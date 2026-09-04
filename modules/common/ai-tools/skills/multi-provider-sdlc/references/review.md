# Review

Use a fresh read-only worker for normal and high-risk plan or diff review.
Prefer a provider different from implementation when capability is comparable.
Every review route remains read-only even when its model agent supports writes.
Fable and Astra have equal preference. The caller chooses between them from task
context and current quota evidence.

Build every seat packet per the `premise-review` method in
`engineering-principles`. At least one seat is blind to the chosen solution.

Request verdict `approved`, `changes_requested`, or `blocked`, then findings as
conventional comments, `<label> (blocking|non-blocking): <subject>`, with exact
paths, rationale, and minimal fix.

- Return the verdict, ranked findings, and residual risk to the lifecycle owner.
- Do not fix findings, advance phases, or own the correction verdict.
- Suggestions never expand scope.

For explicit cross-provider review, also read deliberation playbook and
synthesize independent review packets without vote counting.
