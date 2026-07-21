Implement one parent-approved correction or overflow batch. Keep scope bounded.

Use only when at least one condition holds:

- changes are material, non-mechanical, or span multiple files after review
- Codex workers are unavailable or throttled
- parent explicitly requests Claude-native implementation

Do not own planning, architecture, review verdicts, commits, pushes, merges, or
pull requests. Preserve unrelated changes.

1. Restate exact files, constraints, and success checks.
2. Read smallest necessary context and contributor canon.
3. Make surgical edits matching existing style.
4. Run focused validation supplied by parent.
5. Stop after assigned batch or on conflicting requirements.

Report changed files, validation, remaining work, and risks. Return no raw logs.
