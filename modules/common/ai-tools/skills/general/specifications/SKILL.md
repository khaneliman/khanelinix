---
name: specifications
description: Write clear, actionable specifications for features, bugs, and improvements. Use when documenting requirements, defining acceptance criteria, specifying user experiences, or providing technical context for implementations.
---

# Specification Writing Guide

Guides how to write clear, actionable specifications for features, bugs, and
improvements in any application.

## Core Principles

1. **Write user-focused specifications** - Focus on what the user experiences,
   not implementation details
2. **Be specific and verifiable** - Each requirement should be testable and
   measurable
3. **Follow existing patterns** - Look at current features and maintain
   consistency
4. **Identify relevant files** - Always include tech notes listing related files
5. **Consider all scenarios** - Think about happy paths, edge cases, and error
   conditions
6. **Define success clearly** - Specify how to measure if the feature works
   correctly

## Specification Writing Workflow

Copy this checklist when writing a specification:

```
Specification Progress:
- [ ] Step 1: Understand the problem or requirement
- [ ] Step 2: Read existing code to understand current behavior
- [ ] Step 3: Identify relevant files and their relationships
- [ ] Step 4: Map the user journey and interactions
- [ ] Step 5: Define acceptance criteria clearly
- [ ] Step 6: Consider edge cases and error states
- [ ] Step 7: Specify success metrics
- [ ] Step 8: Document technical context (files, patterns)
```

### Step 1: Understand the Problem

Clarify the need:

- What problem does this solve for users?
- What's the current gap or limitation?
- Who is affected?
- Why is this important?

### Step 2: Read Existing Code

Understand current behavior:

```bash
# Find related features
grep -r "similar_feature" .

# Read current implementations
cat src/components/RelatedComponent.tsx

# Check existing patterns
find . -name "*Pattern*"
```

### Step 3: Identify Relevant Files

Map out the codebase:

- Which files contain related functionality?
- What components, services, or utilities are involved?
- Where would new code likely go?
- What tests cover this area?

### Step 4: Map User Journey

Outline interactions:

- How does the user access this feature?
- What steps do they take?
- What feedback do they receive?
- Where do they go next?

### Step 5: Define Acceptance Criteria

Make requirements testable:

- What must work for this to be complete?
- How will we know it works correctly?
- What behaviors are expected?
- What constraints must be met?

### Step 6: Consider Edge Cases

Think about error conditions:

- What if the network fails?
- What if data is missing?
- What if the user provides invalid input?
- What if the operation takes too long?

### Step 7: Specify Success Metrics

Define measurable outcomes:

- How will we verify it works?
- What performance standards must be met?
- What error rates are acceptable?
- How will users benefit (measurably)?

### Step 8: Document Technical Context

Provide implementation guidance:

- List all relevant files with explanations
- Note existing patterns to follow
- Identify dependencies or prerequisites
- Highlight potential challenges

## Specification Templates

### Feature Specification Template

```markdown
**Title**: [Clear, user-focused feature name]

## Problem Statement

**User problem:**

- What challenge do users face?
- What limitation exists today?
- Why is this painful or important?

**Current state:**

- How do users work around this today?
- What's missing from the current experience?

## User Story

As a [user type], I want to [action/capability], So that [benefit/outcome].

## User Journey

1. **Entry point**: [How users access this feature]
2. **Primary actions**: [Step-by-step user interactions]
3. **Feedback**: [What users see/hear at each step]
4. **Completion**: [How users know they succeeded]

## Acceptance Criteria

Core functionality:

- [ ] [Primary feature behavior - must be verifiable]
- [ ] [Secondary feature behavior - must be testable]

User interface:

- [ ] [UI elements present and correctly labeled]
- [ ] [Interactions work as expected]
- [ ] [Visual feedback provided appropriately]

Data handling:

- [ ] [Data flows correctly through the system]
- [ ] [Data validation works properly]
- [ ] [Data persists/updates as expected]

Error handling:

- [ ] [Error states handled gracefully]
- [ ] [User receives helpful error messages]
- [ ] [Recovery paths exist for failures]

Loading states:

- [ ] [Progressive loading indicators shown]
- [ ] [Smooth transitions between states]
- [ ] [No jarring content shifts]

Responsive design:

- [ ] [Works correctly on mobile devices]
- [ ] [Adapts properly to desktop screens]
- [ ] [Touch and keyboard interactions supported]

## Edge Cases

| Scenario              | Expected Behavior                 |
| --------------------- | --------------------------------- |
| [Unusual condition 1] | [How system should respond]       |
| [Error condition 2]   | [What user should see/experience] |
| [Boundary case 3]     | [How to handle this situation]    |

## Success Metrics

**Verification criteria:**

- [How to test this feature works]
- [What behaviors to verify]
- [Performance benchmarks to meet]

**User benefit:**

- [Measurable improvement for users]
- [Time saved or efficiency gained]
- [Problems solved or prevented]

## Dependencies

**Prerequisites:**

- [Existing features required]
- [Data or systems needed]
- [External services involved]

**Related features:**

- [Features that interact with this]
- [Potential conflicts to consider]

## Tech Notes

### Relevant Files

- `src/components/MainComponent.tsx` - [Why relevant: contains UI that will be
  extended]
- `src/services/DataService.ts` - [Why relevant: handles API calls this feature
  needs]
- `src/hooks/useFeature.ts` - [Why relevant: custom hook that manages feature
  state]
- `src/types/Feature.ts` - [Why relevant: type definitions that may need
  updates]
- `src/utils/validation.ts` - [Why relevant: validation logic to be reused]

### Existing Patterns

- [Pattern 1: how similar features are implemented]
- [Pattern 2: what conventions to follow]
- [Pattern 3: what libraries or frameworks to use]

### Implementation Notes

- [Technical consideration 1]
- [Potential challenge 2]
- [Architectural decision 3]
```

### Bug Fix Specification Template

```markdown
**Title**: [Clear description of the issue]

## Current Behavior

**What happens:**

- [Describe the buggy behavior]
- [Include error messages if any]
- [Note unexpected UI states]

**When it happens:**

- [Specific conditions that trigger it]
- [Frequency: always, sometimes, rarely]

## Expected Behavior

**What should happen:**

- [Correct behavior description]
- [Proper system response]
- [Expected user experience]

## Steps to Reproduce

1. [Specific action with exact UI elements]
2. [Next action with details]
3. [Final step that triggers the bug]

**Result:** [What you see when bug occurs] **Expected:** [What you should see
instead]

## Impact Assessment

| Aspect             | Assessment                                 |
| ------------------ | ------------------------------------------ |
| **Users affected** | [All users / specific group / edge case]   |
| **Severity**       | [Blocking / high / medium / low]           |
| **Frequency**      | [Every time / often / occasionally / rare] |
| **Workaround**     | [Available / difficult / none]             |

## Context

**Environment:**

- Browser/device: [If relevant]
- Version: [If applicable]
- User configuration: [If relevant]

**Additional info:**

- [Screenshots or error logs]
- [Related issues or tickets]
- [When this started occurring]

## Success Criteria

- [ ] Bug no longer occurs when following reproduction steps
- [ ] No regression in related functionality
- [ ] Appropriate error handling added if needed
- [ ] Root cause identified and documented
- [ ] Similar bugs in related code checked

## Tech Notes

### Relevant Files

- `src/buggy/Component.tsx:45` - [Why relevant: contains the buggy code]
- `src/services/BuggyService.ts` - [Why relevant: where error originates]
- `src/utils/helper.ts` - [Why relevant: utility function involved in bug]

### Root Cause Analysis

- [Preliminary analysis of why bug occurs]
- [Code paths involved]
- [Dependencies that may be factors]
```

### Improvement Specification Template

```markdown
**Title**: [Area being improved]

## Current State

**How it works today:**

- [Current functionality description]
- [Current user experience]
- [Current performance characteristics]

**Limitations:**

- [Pain point 1]
- [Inefficiency 2]
- [Frustration 3]

## Proposed Improvement

**Changes:**

- [Specific change 1 with rationale]
- [Specific change 2 with rationale]
- [Specific change 3 with rationale]

**User experience improvement:**

- [How UX gets better]
- [What becomes easier/faster]
- [What frustrations are eliminated]

## User Impact

**Who benefits:**

- [User group 1 and how]
- [User group 2 and how]

**Workflows improved:**

- [Task 1 becomes easier because...]
- [Task 2 becomes faster because...]
- [Task 3 becomes more reliable because...]

## Acceptance Criteria

- [ ] [Specific improvement 1 - measurable]
- [ ] [Specific improvement 2 - testable]
- [ ] [Performance metric: X% faster]
- [ ] [Usability metric: Y fewer clicks]
- [ ] [Backward compatibility maintained]
- [ ] [No regression in related features]

## Success Metrics

**Measurements:**

- [Quantifiable improvement 1]
- [Quantifiable improvement 2]
- [User satisfaction indicator]

**Verification:**

- [How to test improvement works]
- [What benchmarks to run]
- [User feedback to collect]

## Tech Notes

### Relevant Files

- `src/slow/Component.tsx` - [Why relevant: current implementation to optimize]
- `src/services/SlowService.ts` - [Why relevant: bottleneck to address]
- `src/hooks/useOptimization.ts` - [Why relevant: performance pattern to apply]

### Performance Considerations

- [Current performance baseline]
- [Target performance goals]
- [Trade-offs considered]
```

## AI Feature Guidelines

When specifying AI-powered features, always include:

### AI Behavior Specification

```markdown
## AI Behavior

**Model capabilities:**

- [What the AI should be able to do]
- [What types of inputs it handles]
- [What outputs it generates]

**Prompt strategy:**

- [High-level description of AI instructions]
- [Key constraints or guidelines]
- [Expected response format]

**Streaming UX:**

- [How real-time responses display]
- [Progressive disclosure of content]
- [User control during generation]

**Error handling:**

- [What happens when AI call fails]
- [How to handle rate limits]
- [Fallback behaviors]
- [User notification strategy]

**Response validation:**

- [How to ensure responses are appropriate]
- [Content filtering requirements]
- [Quality checks to perform]
- [User feedback mechanisms]

**Performance expectations:**

- [Acceptable response times]
- [Token usage considerations]
- [Caching strategy if applicable]
```

## Common Specification Scenarios

### Scenario 1: New user-facing feature

Focus on:

- Clear user problem being solved
- Detailed user journey
- UI/UX specifications
- Error and loading states
- Accessibility requirements

### Scenario 2: Backend feature

Focus on:

- Data flow and transformations
- API contracts and responses
- Performance requirements
- Error handling strategy
- Security considerations

### Scenario 3: Bug fix

Focus on:

- Exact reproduction steps
- Root cause understanding
- Impact assessment
- Verification criteria
- Regression prevention

### Scenario 4: Performance improvement

Focus on:

- Current baseline metrics
- Target performance goals
- Measurement methodology
- Trade-offs and constraints
- Verification process

## Quality Checklist

Before finalizing a specification:

- [ ] Problem is clearly articulated
- [ ] User story is complete and realistic
- [ ] Acceptance criteria are verifiable
- [ ] Edge cases are documented
- [ ] Success metrics are defined
- [ ] All relevant files are listed with context
- [ ] Existing patterns are referenced
- [ ] Dependencies are identified
- [ ] Technical considerations are noted
- [ ] Specification is implementable by any developer
- [ ] No ambiguity in requirements
- [ ] All scenarios covered (happy path, errors, edge cases)

## See Also

- **Implementation planning**: See [coding-plan](../coding-plan/) for
  translating specs into implementation plans
- **Code review**: See [code-review](../code-review/) for verifying
  implementation matches specification
