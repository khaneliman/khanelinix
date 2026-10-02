# Pull Request Creation Play

Use when drafting a PR body from branch changes, notes, review feedback, or
planned work summaries.

## Workflow

1. Resolve repository, current/base branches, remote, diff, related issues, and
   worktree state. For an existing PR, collect commits, files, and checks with
   `scripts/pr_snapshot.py` instead of rebuilding API queries.
2. Detect mandatory PR template. Read `CONTRIBUTING.md`, root and changed-path
   instructions, and directly relevant docs.
3. Preserve the repository's required template and apply the description
   guidance below, including inside template fields.
4. Note contribution gaps: missing tests/docs/issue links, atomic-history
   concerns, licensing/secrets risk, dirty tree, or unpushed commits.
5. Return title/body ready for `gh pr create`.

## Authority and Output

Creating pull request requires explicit user request. Draft title/body by
default. If creation is explicit but branch is dirty, unpushed, or missing
required context, return title/body plus exact blocker. Do not push, force-push,
rebase, amend, or edit files unless separately requested. Create draft PR only
when user asks for draft state.

## Template Discovery (mandatory)

1. Check for:
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `.github/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE/` (directory)
2. If none is found, use the short description guidance below. Template
   discovery details do not belong in the public PR body.
3. If exactly one template exists, apply it.
4. If multiple templates exist, ask the user to choose before drafting.
5. Preserve required sections and branch-protection labels exactly; only add
   content within template placeholders.

## Description

Default to one short paragraph, usually one or two sentences, explaining what
changes and why in the user's voice. This applies with or without a repository
template. Include a related issue link or closing reference when relevant.

Add detail when it affects the reviewer's decision: a breaking change,
migration, dependency, meaningful limitation, or specific question. Include an
upstream reference when it supports that decision. Expand when requested or when
the repository requires more detail.

Keep required template sections, but do not add generic headings, a
changed-files list, or a testing checklist. Leave investigation history,
implementation walkthroughs, and test inventories out of the description; retain
useful detail in commits or documentation. Do not repeat what the diff or
checklist already shows. Keep the conversational voice by selecting fewer
details, not by making sentences dense.
