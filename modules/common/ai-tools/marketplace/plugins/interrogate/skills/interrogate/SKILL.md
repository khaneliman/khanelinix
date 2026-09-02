---
name: interrogate
description: Adversarial multi-reviewer synthesis for contested or high-risk plans and changes. Use for multi-model review, independent angles, challenge, stress-test, or blind-spot requests. Do not use for routine single-reviewer checks.
---

# Interrogate

Spawn independent reviewers across diverse model families to adversarially
review code changes. Each model receives the same problem statement, diff,
rubric, and code-quality lens. Agreement across models is high-confidence signal
only when the agreeing reviewers did not inherit one premise from the packet;
lone-model findings provide exploratory context.

The deliverable is a synthesized lead verdict. Do NOT auto-apply changes.

## Workflow

### 1. Determine Scope

Identify target changes from context:

- Explicit file paths or diffs.
- Feature branches: `git diff main...HEAD` (or target base branch).
- Recent workspace edits and surrounding context files.

### 2. State the Problem and the Claims

Derive the problem the change claims to solve from the issue, commit history,
and PR description. Write it as one paragraph, separate from the author's chosen
solution. List the author's claims as falsifiable assertions. Reviewers challenge
whether the change should exist in this form before whether the code achieves
it, per the `premise-review` method in `engineering-principles`.

### 3. Spawn Reviewers

Launch parallel reviewers using distinct model families or subagents.

Each reviewer receives:

1. Problem statement and repository context. At least one reviewer is blind:
   it receives no author claims, chosen solution, or extraction rationale.
2. Changeset diff and surrounding context.
3. Review rubric from [rubric.md](references/rubric.md).
4. Code-quality lens from
   [code-quality-review.md](references/code-quality-review.md).
5. Prompt template from [reviewer-prompt.md](references/reviewer-prompt.md).

### 4. Synthesize Findings

1. Collect structured findings from all reviewers, premise gate first.
2. Identify consensus findings (raised by 2+ models independently). Reviewers
   that accepted the same handed premise count as one; a premise finding from
   the blind reviewer outranks implementation consensus.
3. Identify lone-model findings and assess confidence.
4. Deduplicate overlapping issues across models.
5. Note explicit disagreements between reviewers.

### 5. Apply Lead Judgment

Act as lead reviewer using [lead-judgment.md](references/lead-judgment.md):

- **Act on**: Core issues affecting correctness, security, or maintainability.
- **Consider**: Valid tradeoffs worth user attention.
- **Noted**: Low-priority or premature concerns.
- **Dismissed**: False positives or nitpicks lacking context.

## Output Format

Present the synthesized verdict:

- **Problem**: Claimed problem and whether the change should exist in this form.
- **Premise gate**: Merged premise comments and any redesign or closure call.
- **Reviewers**: Model names and findings count.
- **Act On**: Critical issues with model sources and impact rationale.
- **Consider**: Tradeoffs and potential improvements.
- **Noted**: Low-priority observations.
- **Dismissed**: Filtered findings with rejection reasons.
- **Agreement Map**: Consensus and divergence summary across models.
