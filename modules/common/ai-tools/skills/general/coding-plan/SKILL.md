---
name: coding-plan
description: Write clear, actionable coding plans for implementing features, bug fixes, and improvements. Use when planning code changes, designing implementation strategy, sequencing file modifications, or providing step-by-step implementation guidance.
---

# Coding Plan Writing Guide

Guides how to write clear, actionable coding plans for implementing features,
bug fixes, and improvements in any codebase.

## Core Principles

1. **Write implementation-focused plans** - Focus on specific code changes and
   file modifications
2. **Be precise and actionable** - Each step should be executable without
   guesswork
3. **Consider the codebase** - Understand existing patterns and maintain
   consistency
4. **Follow established architecture** - Respect existing patterns and project
   structure
5. **Think about dependencies** - Order changes logically and consider file
   interdependencies
6. **Provide comprehensive context** - Include all necessary technical details

## Planning Process Workflow

Copy this checklist when creating a coding plan:

```
Coding Plan Progress:
- [ ] Step 1: Analyze the task and requirements thoroughly
- [ ] Step 2: Read existing code and understand current state
- [ ] Step 3: Search for similar patterns in codebase
- [ ] Step 4: Identify all files that need modification
- [ ] Step 5: Determine logical sequence of changes
- [ ] Step 6: Write step-by-step instructions for each change
- [ ] Step 7: Document architectural decisions and trade-offs
- [ ] Step 8: Review plan for completeness and clarity
```

### Step 1: Analyze the Task

Understand completely:

- What are the requirements?
- What's the desired outcome?
- What are the acceptance criteria?
- What edge cases must be handled?

### Step 2: Read Existing Code

**Always start by reading the root README** to understand the project structure.

Then use tools to explore:

```bash
# Find relevant files
find . -name "*feature*" -type f

# Read implementation files
cat src/components/FeatureComponent.tsx

# Understand patterns
grep -r "similar_pattern" .
```

### Step 3: Search for Patterns

Find similar implementations:

- How are similar features built?
- What patterns does the project follow?
- What libraries or frameworks are used?
- What naming conventions exist?

### Step 4: Identify Files to Modify

Map out which files need changes:

- Which files contain the relevant code?
- What new files need to be created?
- What files will be affected by changes?
- Are there tests that need updating?

### Step 5: Determine Change Sequence

Order modifications logically:

1. **Dependencies first** - Models, types, interfaces
2. **Core logic** - Business logic, services
3. **Integration** - API endpoints, repositories
4. **Presentation** - UI components
5. **Tests** - Unit and integration tests
6. **Configuration** - Settings, environment

### Step 6: Write Clear Instructions

For each file change:

- Explain WHY this file needs to change
- Show WHAT code changes are needed
- Include context about HOW it fits into the plan
- Provide specific implementation notes

### Step 7: Document Decisions

Explain architectural choices:

- Why this approach over alternatives?
- What trade-offs were considered?
- What patterns are being followed?
- What constraints influenced decisions?

### Step 8: Review Plan

Before finalizing:

- Does the plan address all requirements?
- Are changes ordered correctly?
- Are dependencies handled?
- Is every file change justified?
- Can a developer implement this without guessing?

## Standard Coding Plan Template

````markdown
## Overview

[Concise summary of the task and objectives]

## Approach

[High-level description of the implementation strategy, including:]

- Architecture decisions and rationale
- Key patterns or technologies being used
- Overall sequence of changes
- Important considerations or trade-offs

## File Changes

### `path/to/file1.ts`

**Action:** [Create/Update/Delete]

**Purpose:** [Brief description of what this file does and why it needs to
change]

**Changes:**

```[language]
// Existing code context...
// Remove this line:
console.log('This line will be removed')
// Add this line:
console.log('This line will be added')
// More existing code context...
```
````

Or for simple changes, use diff format:

```diff
- console.log('This line will be removed')
+ console.log('This line will be added')
```

**Notes:**

- [Specific implementation details for this file]
- [Important considerations or potential pitfalls]

### `path/to/file2.tsx`

[Continue with same structure for each file...]

## Dependencies & Prerequisites

- [Any external dependencies that need to be installed]
- [Prerequisites that must be completed first]
- [Environment setup requirements]

## Testing Strategy

- [How to test the implementation]
- [What test cases to cover]
- [Manual testing steps]

## Rollback Plan

- [How to revert changes if needed]
- [What to watch for after deployment]

````
## Code Change Guidelines

### Code Snippet Rules

1. **Minimal context** - Only show code surrounding the actual changes
2. **Clear change indication** - Use comments or descriptive text for changes
3. **Proper formatting** - Use code blocks with language identifiers
4. **Diff blocks** - For removals and additions, use `diff` with `+` and `-`
5. **Avoid large blocks** - Don't include extensive unchanged code
6. **Include imports** - Show necessary import statements when adding dependencies
7. **Show types** - Include TypeScript types when relevant

### File Organization Rules

1. **Logical ordering** - Sequence files so dependencies are implemented first
2. **Clear actions** - Specify whether each file is created, updated, or deleted
3. **Focused purpose** - Each file entry should have a clear, single purpose
4. **Comprehensive coverage** - Include all files that need modification

## Code Change Examples

### Example 1: Adding a new feature

```markdown
### `src/components/UserProfile.tsx`

**Action:** Update

**Purpose:** Add avatar upload functionality to user profile component

**Changes:**

```diff
 import React, { useState } from 'react';
+import { AvatarUpload } from './AvatarUpload';

 export const UserProfile = ({ user }) => {
   const [isEditing, setIsEditing] = useState(false);
+  const [avatar, setAvatar] = useState(user.avatar);

   return (
     <div className="user-profile">
+      <AvatarUpload
+        currentAvatar={avatar}
+        onUpload={setAvatar}
+      />
       <h1>{user.name}</h1>
     </div>
   );
 };
````

**Notes:**

- AvatarUpload component handles file validation and upload
- avatar state syncs with user.avatar on successful upload
- Component uses existing upload utility from `src/utils/upload.ts`

````
### Example 2: Fixing a bug

```markdown
### `src/services/auth.ts`

**Action:** Update

**Purpose:** Fix token expiry check to prevent premature logout

**Changes:**

```diff
 export const isTokenValid = (token: Token): boolean => {
   const now = Date.now();
-  return token.expiresAt > now; // Bug: using milliseconds vs seconds
+  return token.expiresAt * 1000 > now; // Convert seconds to milliseconds
 };
````

**Notes:**

- API returns `expiresAt` in seconds (Unix timestamp)
- JavaScript Date.now() returns milliseconds
- This bug caused tokens to appear expired immediately

````
### Example 3: Refactoring for simplicity

```markdown
### `src/utils/validation.ts`

**Action:** Update

**Purpose:** Consolidate repetitive validation functions into generic validator

**Changes:**

```diff
-export const validateEmail = (email: string): boolean => {
-  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
-  return regex.test(email);
-};
-
-export const validatePhone = (phone: string): boolean => {
-  const regex = /^\d{3}-\d{3}-\d{4}$/;
-  return regex.test(phone);
-};
-
-export const validateZip = (zip: string): boolean => {
-  const regex = /^\d{5}$/;
-  return regex.test(zip);
-};
+export const validateWithRegex = (value: string, regex: RegExp): boolean => {
+  return regex.test(value);
+};
+
+export const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
+export const PHONE_REGEX = /^\d{3}-\d{3}-\d{4}$/;
+export const ZIP_REGEX = /^\d{5}$/;
````

**Notes:**

- Reduces code duplication from 15 lines to 7 lines
- Makes adding new validations easier
- Regex patterns are now reusable constants
- Update all call sites to use: `validateWithRegex(email, EMAIL_REGEX)`

````
## Common Planning Scenarios

### Scenario 1: New feature implementation

Plan structure:
1. Create data models/types
2. Implement business logic
3. Add API endpoints
4. Build UI components
5. Add tests
6. Update documentation

Focus on:
- Following existing patterns
- Handling error cases
- Considering edge cases
- Performance implications

### Scenario 2: Bug fix

Plan structure:
1. Identify root cause
2. Fix the bug
3. Add tests to prevent regression
4. Verify fix doesn't break related code

Focus on:
- Understanding why the bug occurred
- Fixing root cause, not symptoms
- Testing similar code paths
- Documenting the fix

### Scenario 3: Refactoring

Plan structure:
1. Understand current implementation
2. Plan improved structure
3. Refactor in small, testable steps
4. Verify functionality preserved
5. Update tests

Focus on:
- Preserving existing behavior
- Maintaining test coverage
- Improving clarity/performance
- Avoiding scope creep

## Quality Checklist

Before finalizing a coding plan:

- [ ] All necessary files are identified and included
- [ ] Changes are ordered logically for implementation
- [ ] Code snippets show clear before/after states
- [ ] Instructions are specific and actionable
- [ ] Existing patterns and conventions are followed
- [ ] Dependencies and imports are properly handled
- [ ] Error handling and edge cases are considered
- [ ] The plan addresses all requirements from specifications
- [ ] Performance and security considerations are addressed
- [ ] Rollback procedures are outlined
- [ ] Each step can be implemented independently
- [ ] Testing strategy is defined
- [ ] All architectural decisions are justified

## Anti-Patterns to Avoid

### ❌ Don't: Write vague instructions

```markdown
# Bad
Update the user service to handle the new feature.
````

**Why bad?** No specific file, no code changes shown, no context.

### ✅ Do: Provide specific, actionable steps

````markdown
# Good

### `src/services/user.ts`

**Action:** Update

**Purpose:** Add email verification method for new signup flow

**Changes:**

```typescript
export class UserService {
  // Add new method after createUser
  async verifyEmail(token: string): Promise<boolean> {
    const user = await this.findByVerificationToken(token);
    if (!user || user.emailVerified) {
      return false;
    }

    user.emailVerified = true;
    user.verificationToken = null;
    await this.save(user);

    return true;
  }
}
```
````

**Notes:**

- Validates token and marks email as verified
- Returns false if token invalid or email already verified
- Clears verification token after successful verification

````
### ❌ Don't: Include entire file contents

```markdown
# Bad
[Shows 500 lines of code with one 2-line change buried in it]
````

**Why bad?** Wastes tokens, hard to find the actual change.

### ✅ Do: Show minimal context around changes

````markdown
# Good

```diff
 export class AuthService {
   async login(credentials: Credentials) {
     const user = await this.validateCredentials(credentials);
+    if (!user.emailVerified) {
+      throw new UnverifiedEmailError();
+    }
     return this.createSession(user);
   }
 }
```
````

```
## See Also

- **Code review**: See [code-review](../code-review/) for reviewing implemented plans
- **Specifications**: See [specifications](../specifications/) for requirements that inform plans
```
