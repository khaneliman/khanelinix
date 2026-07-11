# GitHub Issue Discovery

Use for finding, filtering, ranking, and summarizing many GitHub issues.

## Workflow

1. Use named repository exactly. Otherwise use current checkout; for explicit
   upstream work, resolve upstream remote and state choice.
2. Run bounded scan:

   ```bash
   python "<path-to-skill>/scripts/issue_scan.py" \
     --repo "OWNER/REPO" \
     --query "is:issue is:open -linked:pr" \
     --limit 100 --top 25
   ```

3. Adjust `--sort comments|created|updated|best-match` and `--order` only when
   request needs it. Helper always forces `is:issue` and rejects pull-request
   type qualifiers. Keep repository scope in `--repo`, not query.
4. Use returned total, fetched sample, label counts, comment ranking, incomplete
   flag, and truncation reasons. Report sampling/API limits instead of implying
   exhaustiveness.
5. Read selected issue bodies/comments only after narrowing candidates. Do not
   invent priority without repository evidence.

Use GitHub search directly only for cross-repository/global discovery that this
repository-scoped helper intentionally does not cover.

## Output

Report repository and selection reason, filters, sample size and API limits, top
labels/categories, and recommended issues with number, title, URL, labels, and
evidence-backed selection reason. Report inconsistent results openly.
