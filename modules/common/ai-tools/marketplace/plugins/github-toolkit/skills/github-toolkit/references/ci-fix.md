# CI Fix Play

Use for failing checks in PR linked to current branch or provided PR.

## Workflow

1. Verify auth: `gh auth status`.
2. Resolve PR with `gh pr view --json number,url` or user-provided PR
   number/URL.
3. Summarize failures:

   ```bash
   python "<path-to-skill>/scripts/inspect_pr_checks.py" --repo "." --pr "<num-or-url>"
   ```

   Add `--json` when machine-friendly output is needed.
4. For each failure, report check name, details URL/run link, and short failure
   context.
5. Do not attempt non-GitHub-actions providers; return URL only and stop.
6. Ask explicit approval before implementing fixes.

If `gh pr checks` field shape changes, rerun with reported accepted fields.
