# Maintainer Queue

Use this mode for a bounded maintenance pass across one repository's issues,
pull requests, review feedback, and failing checks. Produce an evidence-backed
work queue. Do not turn queue inspection into an unbounded backlog project.

Frame repository, objective, available time, sample bounds, and GitHub write
authority first. If the user names several repositories, keep one queue per
repository and report cross-repository limits.

## Collect

Read contributor guidance, issue and pull-request templates, support policy,
release policy, and `SECURITY.md` before classification. Follow private security
reporting rules. Do not move sensitive reports into a public queue.

Collect a bounded live snapshot. Run independent read-only collection in
parallel when available.

- Use `scripts/issue_scan.py --query "is:open" --sort updated` for the all-open
  issue count and a bounded issue sample. Do not use its default `-linked:pr`
  filter for coverage totals. A comments sort measures discussion volume, not
  priority.
- Get the open pull-request count with one bounded search request:

  ```bash
  gh api --method GET /search/issues \
    -f 'q=repo:OWNER/REPO is:pr is:open' -F per_page=1 \
    --jq '{total: .total_count, incomplete_results: .incomplete_results}'
  ```

- Use
  `gh pr list --state open --limit LIMIT --json
  number,title,url,isDraft,reviewDecision,statusCheckRollup,labels,author,updatedAt`
  for the open pull-request sample. Separate drafts, review-ready work, blocked
  reviews, and failing checks.
- Use `scripts/pr_snapshot.py` only after selecting a pull request for deeper
  review or CI analysis.
- Read issue bodies, comments, linked work, and check logs only after narrowing
  candidates.

Search policy-targeted queues outside the recent maintainer sample when the
repository policy exposes searchable markers. Run bounded searches for release
blockers and supported-branch breakage, then deduplicate them against the recent
issue and pull-request samples. Use the exact policy labels, milestones, branch
names, or body markers. If policy has no searchable markers, state that the
result is limited to the recent maintainer sample and cannot establish coverage
of release blockers or supported-branch breakage.

Report totals, fetched counts, truncation reasons, incomplete results, and all
sampling and API limits. For either collector, if its request fails or
`incomplete_results` is true, report `total: unknown` with the fetched count,
limit, and raw reported count when available. Never infer a total from a bounded
or incomplete sample.

## Normalize

Create one queue record per candidate:

```text
kind
number
url
status
last_activity
labels
linked_work
evidence
next_action
blocked_by
write_authority
```

Separate confirmed facts from inference. Detect duplicates and linked pull
requests before recommending implementation. Do not infer impact from title,
age, reactions, or discussion volume alone.

## Prioritize

Apply repository policy first. Then order items by evidence that the repository
defines as important:

1. active release blocker, supported-branch breakage, or private security route;
2. confirmed regression or user-impacting failure with reproduction evidence;
3. maintainer commitment, accepted roadmap item, or requested review;
4. item that cheaply unblocks several confirmed dependents;
5. maintenance with a clear contract and verification path.

Comment count is not priority. Age is not proof that an issue is stale or safe
to close. When policy or evidence cannot order two items, show the tie instead
of inventing a score.

Fit the recommended `act now` set to the stated time budget. Keep blocked and
waiting work visible, but do not let it consume the active work limit.

## Route

Route each selected item to one existing mode or lifecycle:

- classification, duplicate checks, and next-step draft: `issue-triage`;
- pull-request assessment or review draft: `pr-review`;
- existing review threads: `pr-feedback`;
- failing check evidence and fix context: `ci-fix`;
- bounded source change: pass through `issue-triage`, read
  [agent-brief.md](agent-brief.md), then hand its durable brief to
  `engineering-workflow`;
- large, cross-cutting, or unattended source program: `figure-it-out`.

Maintainer queue does not own source mutation. Stop this mode at the handoff
contract. The selected mutation owner grounds code, plans slices, verifies,
reviews, and commits under its own authority.

## Authority

Queue mode is read-only. Draft possible comments, labels, assignments, closes,
review submissions, or other GitHub changes without applying them.

When the user explicitly requests a GitHub write, preview the exact write and
route one selected item to its matching GitHub mode. Authority for one selected
item or operation does not grant another. Source-edit, local-commit, push,
pull-request, merge, release, and deployment grants remain separate.

## Output

Return a compact queue with:

- **Act now**: ordered items that fit the current objective and time budget;
- **Waiting**: blocked items, missing facts, and the actor needed next;
- **Implementation-ready**: issues with a durable brief and acceptance checks;
- **Draft GitHub writes**: exact proposed comments or state changes, not
  applied;
- **Coverage**: totals, selection rules, sampling and API limits, and snapshot
  time;
- **Next pass**: the condition that should trigger another live scan.

Treat the queue as live external state, not durable memory. Persist only stable
repository policy or an explicit user preference. Do not store issue status,
review state, or check results as durable memory.
