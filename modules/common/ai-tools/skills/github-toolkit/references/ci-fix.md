# CI Triage and Fix

Use for failing CI on a repository, branch, commit, workflow run, or PR. A PR is
optional. Follow the requested scope: diagnosis-only requests end with findings;
fix requests continue through implementation and verification without renewed
approval. GitHub writes follow the parent skill's shared rules.

## Collect Evidence

1. Resolve the repository and target revision from the request and checkout. For
   repository-wide triage, identify the failing branches or runs before
   selecting fixes. Use `gh auth status` when authenticated access is needed.
2. For PR checks, use the bundled collector:

   ```bash
   python "<path-to-skill>/scripts/inspect_pr_checks.py" --repo "." --pr "<num-or-url>"
   ```

   Add `--json` for structured output. If no PR was supplied, resolve it with
   `gh pr view --json number,url` only when the target is a PR. Without a PR,
   use `gh run list` and `gh run view` for the target revision.
3. Inspect failed jobs and logs. Record check name, run URL, revision, and the
   first actionable error. Group failures that share a root cause.
4. For external providers, inspect accessible logs with available tools or
   reproduce the failing command locally. The collector supports GitHub Actions
   logs only; that limitation does not restrict the investigation. If evidence
   is inaccessible, report the URL and missing evidence, then continue
   independent work. Ask for access or logs only when needed to proceed.

If `gh pr checks` field shape changes, rerun with reported accepted fields.

## Diagnose, Fix, and Verify

1. Separate source defects from infrastructure failures, stale runs, and
   unrelated baseline failures. Reproduce the actionable failure when feasible.
2. For fix requests, implement focused corrections using repository guidance and
   relevant domain skills. If called within another workflow, return evidence to
   that owner and continue its implementation and verification phases.
3. Run the failing command or closest available check against the corrected
   revision. Investigate remaining failures within the requested scope.
4. Report causes, changed files, verification results, and unresolved blockers
   with run links. Distinguish local verification from a confirmed passing CI
   run.
