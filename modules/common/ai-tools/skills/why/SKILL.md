---
name: why
description: "Investigate motivation, design rationale, and historical decisions behind code. Queries source control, issue trackers, docs, chat, observability, and error logs in parallel. Use for 'why does X work this way', 'why we picked Y', design rationale, regressions, or postmortems."
---

# Why

Investigate the intent and constraints behind existing code. Identify why code
took its current shape, what alternatives were rejected, and what edge cases or
incidents forced specific defenses.

Companion to `how` (runtime behavior) and `blast-radius` (downstream impact).

## Core Principles

- **Evidence before narrative**: Collect citations first; do not fit evidence to
  an assumed story.
- **Cite everything**: Reference commit hashes, PR numbers, tickets, docs, or
  code comments.
- **Hedge appropriately**: Follow [epistemics.md](references/epistemics.md) to
  separate direct facts from inference.
- **Document gaps**: Null results across searched sources are meaningful data.

## Workflow

### 1. Identify Target and Anchor Code

Parse user question and gather initial git context:

```bash
git blame -L <start>,<end> <file>
git log --follow -p -20 -- <file>
gh pr view <number> --json title,body,author,comments,reviews
```

Record file paths, line ranges, symbols, commit SHAs, and linked ticket numbers.

### 2. Query Evidence Categories in Parallel

Query available evidence systems in parallel using
[investigator-prompt.md](references/investigator-prompt.md):

1. **Source control**: Commits, PR descriptions, review comments, tests
   ([code-archaeology.md](references/sources/code-archaeology.md)).
2. **Connected systems**: Issue trackers, design documents, team chat,
   observability, error tracking, and product analytics, when the session has a
   tool for them. Use that tool's own search and filters.
3. **Defensive code**: Consult
   [incident-postmortem.md](references/sources/incident-postmortem.md) when
   investigating defensive checks.

Skip only systems without an available tool, and record each one in sources
consulted.

### 3. Synthesize and Present

Synthesize findings using
[synthesizer-prompt.md](references/synthesizer-prompt.md):

- **The Question**: Concise restatement.
- **The Code**: Anchoring files, symbols, and line ranges.
- **What We Found**: Claims backed by direct citations.
- **Reasonable Inferences**: Hedged conclusions from converging indirect
  evidence.
- **Competing Hypotheses**: Alternative explanations if evidence is ambiguous.
- **What We Do Not Know**: Unresolved questions and null search results.
- **Sources Consulted**: Coverage map of all queried sources and gap
  justifications.
