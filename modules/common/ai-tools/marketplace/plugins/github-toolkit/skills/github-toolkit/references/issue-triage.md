# Targeted Issue Triage

Use for classifying one issue or a small candidate set and drafting next-step
guidance. Use [issue-discovery.md](issue-discovery.md) for broad searches and
ranking.

## Target Resolution

- Number: current repository unless user names another.
- URL: owner and repository from URL.
- Search text: find a small set of open candidates, then identify exact target.

## Workflow

1. Resolve metadata, labels, comments, linked pull requests, likely duplicates,
   and current status.
2. Read contributor guidance, issue templates, root/local instructions, and
   directly relevant documentation.
3. Classify as bug, feature, docs, question, support, duplicate, stale, or
   needs-info. Separate confirmed facts from inference.
4. Recommend smallest useful next action: request information, link docs, close
   as duplicate/not planned, label/route, or outline implementation.
5. Load matching domain skill before proposing code direction.
6. If the recommended state is ready for agent handoff, read
   [agent-brief.md](agent-brief.md) and draft a durable behavioral contract.

## Authority and Output

Triage is read-only unless user explicitly asks for a GitHub write. Do not
comment, label, close, assign, push, or edit files while only asked to triage.

Return target and classification, evidence and missing information, relevant
guidelines, recommended next action, and concise draft reply. For agent handoff,
return the durable brief instead of a path-bound implementation recipe.
