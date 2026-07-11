# GitHub Issue Discovery

Use for finding, filtering, ranking, and summarizing GitHub issues with `gh`.

## Repository Targeting

1. If user names a repo, use it exactly.
2. With no named repo, use current checkout repository; outside a checkout, stop
   and request target.
3. If user says "upstream", resolve from `git remote -v`.
4. If current checkout is a fork, prefer upstream remote for upstream issue
   discovery and state choice.
5. Verify auth when private data or higher rate limits matter: `gh auth status`.

With no filters, inspect open issues excluding linked pull requests, then
summarize label distribution and a small set of recent or high-discussion
candidates. Do not invent priority without repository evidence.

## Preferred Commands

Repository-scoped list:

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

`gh issue list` has no `commentsCount` field. `comments` returns full comment
objects, so requesting it on large result sets can cause GraphQL 502 responses.
Use REST search for counts:

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
parameters. Without it, `gh api` may send POST and GitHub returns
`404 Not
Found`.

## `gh search issues` Caveats

Use only for global searches across many repositories or when GitHub search is
specifically required.

- For repo-scoped search, pass `--repo OWNER/REPO`; do not put `repo:OWNER/REPO`
  inside quoted query unless local CLI version accepts it.
- For comment counts use `commentsCount`, not `comments`.
- Verify suspicious zero-result advanced searches with `gh issue list` or
  `gh api --method GET /search/issues`.

## Output

Report repository and selection reason, filters, sample size and API limits, top
labels/categories, and recommended issues with number, title, URL, labels, and
selection reason. Report inconsistent command results instead of hiding them.
