# Pull Request Review Authoring

Use for a high-signal review and a draft or explicitly requested pending GitHub
review. Use [pr-feedback.md](pr-feedback.md) for existing review comments.

## Workflow

1. Resolve one target and capture bounded metadata:

   ```bash
   python "<path-to-skill>/scripts/pr_snapshot.py" \
     --repo "OWNER/REPO" --pr "NUMBER_OR_URL"
   ```

   Snapshot defaults to at most 200 files and 100 commits. Check
   `completeness.files` and `completeness.commits` before treating scope as
   exhaustive. Increase `--max-files`/`--max-commits`, or use `0` to fetch
   through GitHub's API hard cap.

2. Stop for closed or draft pull requests, or generated/dependency-only changes
   with no reviewable code.
3. Read contributor guidance, PR template, root and changed-path instructions,
   and directly relevant documentation.
4. Review only diff plus necessary local context. Load matching language/domain
   skill before judging implementation details.
5. Validate each finding against changed code and repository policy.
6. Return draft findings by default. Create or update a pending review only when
   user explicitly requests it.

Never submit pending review, approve, request changes, push, or edit source.
Leave final publication to user in GitHub UI.

## Pending Review Reconciler

Declare desired pending-review state. Give every inline finding a stable key:

```json
{
  "expected_head_sha": "FULL_HEAD_SHA",
  "body": "<!-- ai-tools:review-pr -->\nReview context.",
  "comments": [
    {
      "key": "validated-defect-name",
      "path": "path/to/file",
      "start_line": 10,
      "line": 12,
      "side": "RIGHT",
      "body": "issue (blocking): describe validated defect"
    }
  ]
}
```

Use an empty `comments` array for a body-only or no-findings review. Plan first.
Add `--apply` only when user explicitly requested pending-review creation or
update:

```bash
python "<path-to-skill>/scripts/review_draft.py" reconcile \
  --repo "OWNER/REPO" --pr "NUMBER_OR_URL" --input review.json
```

Reconciler discovers current actor and pending review. It selects create,
update, or no-op. It adds, updates, relocates, and removes keyed comments while
preserving unkeyed comments. Submitted marked reviews do not block a later
review cycle. It adopts one legacy unkeyed comment only when its anchor and
visible body match a desired keyed comment. Re-running same desired input
converges after partial writes.

Reconciler enforces open non-draft state, exact head and base SHAs,
current-actor ownership, one review marker, unique comment keys, and current
diff anchors. It rejects unknown fields and has no review-submission event
surface. Use helper for supported review mechanics. Do not discover or assemble
ad hoc GitHub review mutations.

After `--apply`, inspect `applied`, `mutation`, and `verification.status`.
`unverified` means a write may have completed without exact readback. `partial`
lists attempted and confirmed operations before a later update fails. Run same
reconcile input again. Reconciler reads current state and plans only remaining
work. Only `verified` proves exact desired review body, keyed comments, anchors,
pending state, actor, and PR revisions.

Legacy `inspect`, `create`, and `update` commands remain for compatibility.
Prefer `reconcile` for new workflows.

## High-Signal Review Policy

Flag only highly likely defects:

- syntax, type, compile, or unresolved-reference failures
- logic that definitely produces wrong behavior
- clear security or data-loss defects in changed code
- clear instruction-file violations scoped to changed file
- clear contribution-policy violations: commit message, atomicity, required
  tests/checks, licensing, or secrets

Do not flag style, subjective quality, pre-existing problems, speculative edge
cases, duplicates, or normal linter findings unless repo instructions require.
Validate each issue against diff and relevant local instructions.

Do not re-run green CI checks merely to restate them. Judge whether checks cover
changed behavior; missing coverage can be a finding when repository policy or
risk requires it.

## Review Writing

- Keep review body to outcome, confidence, and global context. Do not duplicate
  inline findings.
- Write one inline comment per unique issue: problem, reason, next step.
- Keep each discussion to 1-3 short sentences unless evidence requires more.
- Use suggestion blocks only when they fully fix the selected line range.
- Cite local instructions for compliance findings and concrete commit SHAs for
  code links.

Format inline comments as:

```markdown
<label> [decorations]: <subject>

[necessary evidence, reasoning, and next step]
```

Use `issue`, `suggestion`, `question`, `nitpick`, `note`, `praise`, or `todo`.
Use `(blocking)` only for high-signal defects; otherwise use `(non-blocking)` or
omit decoration. Keep one primary label.

No-issues comment when requested:

```markdown
## Code review

No issues found. Checked for bugs and repository instruction/contribution
compliance.
```
