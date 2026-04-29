# GitHub Issue Triage Reference

Use this reference for finding, filtering, ranking, and summarizing GitHub
issues with `gh`.

## Contents

- Repository Targeting
- Preferred Commands
- Comment Counts and Search Metadata
- `gh search issues` Caveats
- Reporting Checklist

## Repository Targeting

1. Determine the target repository before searching.
   - If the user names a repository, use that exact repository.
   - If the user says "upstream", resolve it from `git remote -v`.
   - If the current checkout is a fork, prefer the upstream remote for upstream
     issue discovery and say so.
2. Verify auth if private data or higher rate limits matter:

```sh
gh auth status
```

## Preferred Commands

Prefer `gh issue list` for normal repository-scoped issue discovery.

Filtered issue list:

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

Do not request `comments` from `gh issue list` for large result sets unless
comment bodies are actually needed. In `gh issue list`, `comments` is an array
of comment objects, not a cheap count, and there is no `commentsCount` JSON
field. Large `--json comments` queries can fail with GraphQL 502 responses.

Use the REST search endpoint when you need comment counts, sorting by comments,
or other search metadata without fetching comment bodies.

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

Always include `--method GET` with `gh api /search/issues` when passing `-f`
parameters. Without it, `gh api` may send a POST request and GitHub returns
`404 Not Found`; that is a method problem, not a repository or auth problem.

## `gh search issues` Caveats

Use `gh search issues` only for global searches across many repositories or when
GitHub's search endpoint is specifically needed.

- For repository-scoped search, pass the repository with `--repo OWNER/REPO`.
- Do not put `repo:OWNER/REPO` inside a quoted query unless you have verified
  the local CLI version accepts it.
- For comment counts, request `commentsCount`, not `comments`.
- If `gh search issues` returns zero or suspicious results for advanced
  qualifiers such as `-linked:pr`, verify with `gh issue list` or
  `gh api --method GET /search/issues` before trusting it.

## Reporting Checklist

Summaries should explain:

- repository searched and why
- filters used, including whether linked PRs were excluded
- sample size and any API/CLI limitations
- top labels or categories
- recommended issues with issue number, title, URL, labels, and why each is a
  good candidate

If results look inconsistent across commands, report the inconsistency and use
the command whose output is easiest to verify.
