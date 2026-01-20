---
name: code-review
description: Conduct thorough, actionable code reviews focusing on critical issues. Use when reviewing pull requests, analyzing code changes, identifying bugs, security vulnerabilities, or suggesting improvements that developers will actually implement.
---

# Code Review Guide

Conducts thorough, actionable code reviews that focus on critical issues
requiring immediate attention while maintaining a high ratio of
suggestion-to-implementation.

## Core Principles

1. **Focus on critical issues** - Prioritize bugs, security vulnerabilities, and
   performance problems over style preferences
2. **Be actionable and specific** - Every suggestion should include concrete
   code improvements with file paths and line numbers
3. **Be concise** - Provide clear, direct feedback without unnecessary
   elaboration
4. **Investigation before suggestions** - Focus on the PR diff, but when you
   think you might have a suggestion, ALWAYS investigate the broader codebase
   first
5. **Understand the codebase** - Consider existing patterns, architecture, and
   project conventions
6. **Maximize implementation value** - Suggest changes that developers will
   actually want to implement
7. **Avoid bikeshedding** - Skip subjective preferences that don't affect
   functionality or maintainability
8. **Make persuasive cases** - For subjective suggestions, provide clear,
   compelling arguments with concrete benefits

**Scoring mindset**: Each accepted suggestion scores +1, each ignored suggestion
scores -1. Focus on suggestions developers will implement.

## Review Process Workflow

Copy this checklist when conducting a code review:

```
Code Review Progress:
- [ ] Step 1: Understand the change context and scope
- [ ] Step 2: Examine the diff thoroughly
- [ ] Step 3: Investigate broader codebase for patterns
- [ ] Step 4: Identify critical issues (bugs, security, performance)
- [ ] Step 5: Look for clear simplification wins
- [ ] Step 6: Verify suggestions against actual code
- [ ] Step 7: Provide actionable feedback with examples
```

### Step 1: Understand Context

Read the PR description, commit messages, and understand:

- What problem is being solved?
- What functionality is being added/changed?
- What's the intended user experience?

### Step 2: Examine the Diff

Review all modified files:

- What files changed?
- What's the scope of changes?
- Are there tests included?

### Step 3: Investigate Broader Codebase

**CRITICAL**: Use search tools before making suggestions:

```bash
# Search for similar patterns
grep -r "similar_function_name" .

# Find related implementations
grep -r "implements.*Interface" .

# Check for existing conventions
grep -r "error handling pattern" .
```

**Why?** Verify your understanding against actual implementations, not
assumptions.

### Step 4: Identify Critical Issues

Focus on high-impact problems that could cause:

- Runtime crashes or errors
- Security vulnerabilities
- Data corruption or loss
- Significant performance degradation
- Logic errors in core functionality

### Step 5: Look for Simplification Wins

Only suggest simplifications when:

- The improvement is clearly beneficial and obvious
- The simplified version is demonstrably easier to understand
- There's no loss of functionality or performance
- You can provide a concrete, working alternative

### Step 6: Verify Suggestions

Before finalizing any suggestion:

- Search the codebase to verify your understanding
- Check that similar code doesn't exist elsewhere
- Confirm your suggestion matches project patterns
- Distinguish between test fixtures and production code

### Step 7: Provide Actionable Feedback

For each issue:

- Include exact file path and line number
- Show before/after code examples
- Explain the impact and why it matters
- Make implementation easy with complete examples

## Review Focus Areas

### Critical Issues (Always Review)

**1. Code bugs or potential runtime errors**

- Null pointer exceptions, undefined variables
- Type mismatches and casting errors
- Logic errors in conditionals and loops
- Incorrect API usage or method calls

**2. Logic errors or incorrect implementations**

- Algorithms that don't match specifications
- Business logic inconsistencies
- Data flow problems
- State management issues

**3. Missing error handling in critical paths**

- Unhandled promise rejections
- Missing try-catch blocks for risky operations
- No fallback for network failures
- Inadequate input validation

**4. Security vulnerabilities (verified through analysis)**

Before flagging security issues:

- Investigate how the code actually works using search tools
- Search for related logic in the broader codebase
- Verify claims by examining actual implementation
- Confirm issues through code analysis, not assumptions

Examples:

- SQL injection vulnerabilities (confirmed through code analysis)
- XSS vulnerabilities (verified as lacking proper escaping)
- Exposed sensitive data (verified as actually sensitive, not test data)
- Authentication/authorization bypasses (verified after investigating auth flow)

**5. Performance issues with significant impact**

- Memory leaks or excessive memory usage
- Inefficient algorithms (O(n²) when O(n) possible)
- N+1 query problems
- Blocking operations on main thread
- Unnecessary re-renders or computations

### Simplification Opportunities (Clear Wins Only)

**6. Obvious complexity reduction**

Only suggest when clearly beneficial:

**Example: Flatten nested conditionals**

```javascript
// Before - deeply nested
if (user) {
  if (user.isActive) {
    if (user.hasPermission) {
      return doAction();
    }
  }
}
return null;

// After - early returns
if (!user || !user.isActive || !user.hasPermission) {
  return null;
}
return doAction();
```

**Example: Extract repetitive patterns**

```javascript
// Before - repetitive
const userAge = data.user?.age ?? 0;
const userName = data.user?.name ?? "";
const userEmail = data.user?.email ?? "";

// After - consolidated
const { age = 0, name = "", email = "" } = data.user ?? {};
```

## Review Categories by Priority

### High Priority (Always Include)

| Issue Type              | Impact                    | Action Required          |
| ----------------------- | ------------------------- | ------------------------ |
| Runtime Errors          | Crashes application       | Fix immediately          |
| Security Flaws          | Exposes vulnerabilities   | Fix before merge         |
| Data Corruption         | Loses or corrupts data    | Fix immediately          |
| Performance Bottlenecks | Significantly degrades UX | Fix or plan optimization |
| Critical Logic Errors   | Core functionality broken | Fix immediately          |

### Medium Priority (Include if Significant)

| Issue Type           | Impact                           | Action Required      |
| -------------------- | -------------------------------- | -------------------- |
| Error Handling Gaps  | Missing error handling           | Add before merge     |
| Type Safety Issues   | Potential type errors            | Fix or add guards    |
| Resource Management  | Memory leaks                     | Fix before merge     |
| API Misuse           | Incorrect library usage          | Fix immediately      |
| Clear Simplification | Reduces complexity significantly | Suggest with example |

### Low Priority (Generally Skip)

| Issue Type              | Why Skip                          |
| ----------------------- | --------------------------------- |
| Style Preferences       | Subjective, low impact            |
| Minor Optimizations     | Minimal benefit                   |
| Documentation           | Unless critical for understanding |
| Speculative Refactoring | No clear functional benefit       |

## Communication Guidelines

### Issue Format

**Bad example (vague):**

```
This code looks wrong and might cause issues.
```

**Good example (specific):**

````
**Bug: Null pointer exception**
File: `src/services/user.ts:45`

Current code:
```javascript
return user.profile.email; // user.profile might be null
````

Issue: If `user.profile` is null, this will throw a runtime error.

Suggested fix:

```javascript
return user.profile?.email ?? "";
```

Impact: Prevents crashes when user profile is not loaded.

````
### Suggestion Format

Use numbered lists, not # symbols:

```markdown
1. **Issue: Memory leak in event listeners**
   File: `src/components/Chat.tsx:127`

   Current:
   ```typescript
   useEffect(() => {
     window.addEventListener('resize', handleResize);
   }, []);
````

Problem: Event listener never removed, causes memory leak.

Fix:

```typescript
useEffect(() => {
  window.addEventListener("resize", handleResize);
  return () => window.removeEventListener("resize", handleResize);
}, []);
```

2. **Issue: Inefficient database query** File: `src/repositories/user.ts:89`

   [Continue with same format...]

````
## Anti-Patterns to Avoid

### ❌ Don't: Make assumptions

```markdown
# Bad
This might be a security issue because users could inject SQL.
````

**Why bad?** Speculation without investigating if the code actually uses SQL or
has proper sanitization.

### ✅ Do: Investigate then report

````markdown
# Good

**Security: SQL Injection vulnerability** File: `src/db/queries.ts:45`

Investigation: Searched codebase for parameterization - found raw string
concatenation.

Current code uses string interpolation:

```javascript
db.query(`SELECT * FROM users WHERE id = ${userId}`);
```
````

Should use parameterized query:

```javascript
db.query("SELECT * FROM users WHERE id = ?", [userId]);
```

Verified: No sanitization exists in data flow from `api/users.ts:23` → this
function.

````
### ❌ Don't: Suggest style preferences without justification

```markdown
# Bad
Consider renaming `getData` to `fetchUserInformation` for clarity.
````

**Why bad?** Subjective naming preference with no concrete benefit stated.

### ✅ Do: Justify suggestions with concrete benefits

```markdown
# Good (if truly beneficial)

**Clarity: Ambiguous function name** File: `src/api/client.ts:78`

Current name `getData` is used for 3 different data types in this file:

- Line 78: fetches user data
- Line 124: fetches product data
- Line 189: fetches order data

This creates confusion when debugging. Suggest:

- `getUserData()` at line 78
- `getProductData()` at line 124
- `getOrderData()` at line 189

Benefit: Reduces debugging time by making call sites self-documenting.
```

## Quality Checklist

Before finalizing a code review:

- [ ] **Investigation completed**: Used search tools to understand broader
      codebase
- [ ] **Suggestions verified**: All suggestions confirmed through code analysis
      beyond PR diff
- [ ] **Critical bugs identified**: Runtime errors found through code
      examination
- [ ] **Security issues verified**: Flagged only after investigating how system
      actually works
- [ ] **Performance issues noted**: Significant bottlenecks identified with
      impact assessment
- [ ] **Clear simplifications**: Only obvious wins included
- [ ] **Specific file paths**: All suggestions include exact locations and line
      numbers
- [ ] **Code examples provided**: Before/after examples for all suggestions
- [ ] **Prioritized by severity**: Issues ordered by impact
- [ ] **Reasoning included**: Technical rationale with evidence from code
      analysis
- [ ] **Actionable changes**: Focus on high-value, implementable suggestions
- [ ] **No speculation**: Only verified issues included

## Common Review Scenarios

### Scenario 1: New feature implementation

Focus areas:

- Does it follow existing patterns?
- Are error cases handled?
- Is there proper validation?
- Does it introduce security risks?
- Are there obvious simplification opportunities?

### Scenario 2: Bug fix

Focus areas:

- Does it actually fix the root cause?
- Are there similar bugs elsewhere?
- Is there proper error handling now?
- Could this fix introduce new bugs?

### Scenario 3: Refactoring

Focus areas:

- Is functionality preserved?
- Are tests updated?
- Is the change clearly simpler?
- Does it maintain performance?

## See Also

- **Implementation planning**: See [coding-plan](../coding-plan/) for writing
  implementation plans based on review feedback
- **Specification writing**: See [specifications](../specifications/) for
  documenting requirements before implementation
