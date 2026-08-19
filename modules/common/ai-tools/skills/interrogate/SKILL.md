---
name: interrogate
description: Multiple LLM reviewers challenge changes from independent angles. Use for "interrogate", "adversarial review", "multi-model review", "challenge this", "stress test this code", "find blind spots", or "tear this apart".
---

# Interrogate

Spawn independent reviewers across diverse model families to adversarially
review code changes. Each model receives the same intent, diff, rubric, and
code-quality lens. Agreement across models is high-confidence signal; lone-model
findings provide exploratory context.

The deliverable is a synthesized lead verdict. Do NOT auto-apply changes.

## Workflow

### 1. Determine Scope

Identify target changes from context:

- Explicit file paths or diffs.
- Feature branches: `git diff main...HEAD` (or target base branch).
- Recent workspace edits and surrounding context files.

### 2. State Intent

Derive what the change accomplishes from user input, commit history, and PR
descriptions. Write one clear paragraph. Reviewers challenge whether the code
achieves this intent well, not the intent itself.

### 3. Spawn Reviewers

Launch parallel reviewers using distinct model families or subagents.

Each reviewer receives:

1. Stated intent.
2. Changeset diff and surrounding context.
3. Review rubric from [rubric.md](references/rubric.md).
4. Code-quality lens from
   [code-quality-review.md](references/code-quality-review.md).
5. Prompt template from [reviewer-prompt.md](references/reviewer-prompt.md).

### 4. Synthesize Findings

1. Collect structured findings from all reviewers.
2. Identify consensus findings (raised by 2+ models independently).
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

- **Intent**: Stated goal of the changes.
- **Reviewers**: Model names and findings count.
- **Act On**: Critical issues with model sources and impact rationale.
- **Consider**: Tradeoffs and potential improvements.
- **Noted**: Low-priority observations.
- **Dismissed**: Filtered findings with rejection reasons.
- **Agreement Map**: Consensus and divergence summary across models.
