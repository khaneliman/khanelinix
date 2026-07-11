# Pull Request Feedback

Use when inspecting or addressing existing review comments. Use
[pr-review.md](pr-review.md) when authoring a new review.

## Workflow

1. Resolve target and head SHA with `scripts/pr_snapshot.py`.
2. Fetch actionable unresolved, non-outdated threads with bounded body previews:

   ```bash
   python "<path-to-skill>/scripts/review_threads.py" inspect \
     --repo "OWNER/REPO" --pr "NUMBER_OR_URL"
   ```

   Add `--include-bodies` only when full prose is needed. Narrow with `--path`,
   `--author`, `--state`, or `--outdated` before loading more context.
3. Read root and changed-path instructions plus contributor guidance.
4. Group actionable, resolved, stale, duplicate, and informational threads.
5. Present actionable items with file/range, request, evidence, and likely fix.
6. Edit only feedback user selected or explicitly asked to address. Validate
   focused changes and report each thread as fixed, declined, or blocked.

Reply or resolve only when explicitly requested. Both commands dry-run unless
`--apply` is present and require current `--expected-head-sha`:

```bash
python "<path-to-skill>/scripts/review_threads.py" reply \
  --repo "OWNER/REPO" --pr "N" --thread "THREAD_NODE_ID" \
  --expected-head-sha "FULL_HEAD_SHA" --body-file reply.md

python "<path-to-skill>/scripts/review_threads.py" resolve \
  --repo "OWNER/REPO" --pr "N" --thread "THREAD_NODE_ID" \
  --expected-head-sha "FULL_HEAD_SHA"
```

Do not submit reviews, push, or publish replies/resolutions without separate
authority.

After `--apply`, treat `applied: true` as write truth even when
`verification.status` is `unverified`. Inspect the returned comment ID or thread
before any retry; readback failure does not undo the mutation.
