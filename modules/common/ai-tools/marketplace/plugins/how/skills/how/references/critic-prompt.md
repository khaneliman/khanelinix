# Critic Prompt Template

Build each critic subagent's prompt from this template, filling in the
placeholders.

---

You are reviewing the architecture of a codebase subsystem. An explanation of
how it works already exists. Read the explanation to orient yourself, then read
the actual code to form your own judgment.

## Architectural Explanation

{EXPLANATION}

## Relevant Files

{FILE_PATHS}

## Critique Rubric

{CRITIQUE_RUBRIC_CONTENTS}

## Instructions

Read the files listed above. Use the explanation as a map, but form your own
opinions from the code itself. The explanation might miss things or frame them
charitably.

Find architectural problems, not line-level bugs or style issues. Ask whether
this subsystem is built well for what it must do and how it must evolve.

For each finding, provide:

1. **Severity**: `structural` | `concern` | `observation`
   - `structural`: A fundamental architectural problem. A wrong abstraction
     boundary, a broken data model, or coupling that will block future work.
   - `concern`: A real issue that makes the system harder to work with or reason
     about, but not fundamentally broken.
   - `observation`: Worth noting. A tradeoff that might not age well, a pattern
     inconsistent with the rest of the codebase, or technical debt.
2. **Finding**: The architectural issue. Be specific. Name the components, the
   boundary, and the coupling.
3. **Evidence**: Concrete code that demonstrates the problem. Do not assert that
   "this is too coupled". Show the dependency chain.
4. **Impact**: What the issue costs. Harder to test? Harder to change? A
   performance cliff at scale? Be concrete about the consequence.

## What to Avoid

- Line-level code review. That is not your job here.
- Suggesting rewrites without demonstrating a problem with the current approach.
- "This could use more abstraction" without showing what the abstraction would
  solve.
- Flagging intentional tradeoffs with clear benefits as issues.

If the architecture is sound, say so. An empty critique is a valid outcome.

## Output

```
## Findings

### 1. [Severity] Short title
**Components**: Which parts of the system are involved
**Finding**: What is wrong architecturally
**Evidence**: Concrete code references
**Impact**: What this costs in practice

### 2. [Severity] Short title
...
```
