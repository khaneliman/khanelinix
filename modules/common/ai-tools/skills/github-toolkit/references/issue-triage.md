# GitHub Issue Triage Reference

Use for finding, filtering, ranking, and summarizing GitHub issues with `gh`.

## Repository Targeting

1. If the user names a repo, use it exactly.
2. If the user says "upstream", resolve from `git remote -v`.
3. If current checkout is a fork, prefer the upstream remote for upstream issue
   discovery — say so.
4. Verify auth when private data or higher rate limits matter: `gh auth status`

## Preferred Commands

Filtered issue list (repository-scoped):

```sh
gh issue list --repo OWNER/REPO --state open --limit 1000 \
  --search "is:issue is:open -linked:pr" \
  --json number,title,url,labels,createdAt,updatedAt
```

Count matching issues:

```sh
gh issue list --repo OWNER/REPO --state open --limit 1000 \
  --search "is:issue is:open -linked:pr" \
  --json number --jq 'length'
```

Aggregate labels:

```sh
gh issue list --repo OWNER/REPO --state open --limit 1000 \
  --search "is:issue is:open -linked:pr" \
  --json labels \
  --jq '[.[].labels[].name] | group_by(.) | map({label: .[0], count: length}) | sort_by(-.count)'
```

Verify advanced qualifiers with a cheap sample before expensive aggregation:

```sh
gh issue list --repo OWNER/REPO --state open --limit 20 \
  --search "is:issue is:open -linked:pr" \
  --json number,title,url
```

## Comment Counts and Search Metadata

**Field-name quirk**: `gh issue list` has no `commentsCount` field. `comments`
returns full comment objects (not a count) — requesting it on large result sets
can cause GraphQL 502 responses. Use the REST search endpoint instead.

Count via REST search:

```sh
gh api --method GET /search/issues \
  -H 'Accept: application/vnd.github+json' \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  -f q='repo:OWNER/REPO is:issue is:open -linked:pr' \
  -f per_page=1 \
  --jq '.total_count'
```

Top issues by comment count:

```sh
gh api --method GET /search/issues \
  -H 'Accept: application/vnd.github+json' \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  -f q='repo:OWNER/REPO is:issue is:open -linked:pr' \
  -f per_page=100 \
  -f sort=comments \
  -f order=desc \
  --jq '.items[:25] | map({number, title, comments, updated_at, url: .html_url, labels: [.labels[].name]})'
```

**Always include `--method GET`** with `gh api /search/issues` when passing `-f`
parameters. Without it, `gh api` may send a POST and GitHub returns
`404 Not Found` — a method problem, not a repo or auth problem.

## `gh search issues` Caveats

Use only for global searches across many repos or when GitHub's search endpoint
is specifically needed.

- For repo-scoped search, pass `--repo OWNER/REPO` — do not put
  `repo:OWNER/REPO` inside a quoted query unless the local CLI version is
  verified to accept it.
- For comment counts use `commentsCount`, not `comments`.
- If `gh search issues` returns zero or suspicious results for advanced
  qualifiers like `-linked:pr`, verify with `gh issue list` or
  `gh api --method GET /search/issues` before trusting it.

## Reporting Checklist

Summaries must include:

- repository searched and why
- filters used (including whether linked PRs were excluded)
- sample size and any API/CLI limitations
- top labels or categories
- recommended issues: number, title, URL, labels, reason to pick each

If results look inconsistent across commands, report the inconsistency and use
the command whose output is easiest to verify.
