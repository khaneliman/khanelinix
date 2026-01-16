---
name: context-gathering
description: Build comprehensive context about codebase areas for prompts, documentation, or onboarding. Use when understanding a feature, preparing documentation, onboarding to new code, or building context for AI prompts.
---

# Context Gathering Guide

Compiles comprehensive information about codebase areas for use in prompts,
documentation, or understanding.

## Core Principles

1. **Purpose-driven** - Gather what's needed, not everything possible
2. **Structured output** - Organize information for easy consumption
3. **Include relationships** - Show how code connects to other parts
4. **Relevant snippets** - Include key code, not entire files
5. **Recent history** - Note recent changes and their context

## Context Gathering Workflow

Copy this checklist when gathering context:

```
Context Gathering Progress:
- [ ] Step 1: Identify scope and boundaries
- [ ] Step 2: Find entry points and main files
- [ ] Step 3: Read core implementation
- [ ] Step 4: Map dependencies and consumers
- [ ] Step 5: Gather type definitions and interfaces
- [ ] Step 6: Check recent git history
- [ ] Step 7: Compile structured output
```

## Scoping the Context

### Scope Levels

| Scope       | What to Include                | Use When                    |
| ----------- | ------------------------------ | --------------------------- |
| **File**    | Single file, immediate imports | Focused debugging/changes   |
| **Module**  | Directory, related files       | Feature work, documentation |
| **Feature** | Cross-cutting concerns         | Understanding workflows     |
| **System**  | Architecture overview          | Onboarding, major changes   |

### Boundary Identification

Ask these questions:

- What files implement this functionality?
- What are the public entry points?
- Where does this connect to other systems?
- What can I safely ignore?

## Information to Gather

### Core Information

1. **Purpose**: What this code does and why it exists
2. **Key Files**: Main implementation files with roles
3. **Public Interface**: Functions, types, and APIs exposed
4. **Configuration**: Settings, constants, environment vars
5. **Tests**: Test files that document behavior

### Relationships

1. **Dependencies**: What this code uses
   - Internal modules
   - External packages

2. **Consumers**: What uses this code
   - Other modules
   - API endpoints
   - UI components

3. **Data Flow**: How information moves through

### History

1. **Recent Changes**: Last 5-10 commits touching this area
2. **Authors**: Who knows this code well
3. **Open Issues**: Related bugs or features

## Output Format

### Standard Context Package

```markdown
# Context: [Topic Name]

## Purpose

[What this code does and why it exists - 2-3 sentences]

## Key Files

| File                | Purpose                               |
| ------------------- | ------------------------------------- |
| `src/auth/login.ts` | Main login logic and session creation |
| `src/auth/types.ts` | User and session type definitions     |
| `src/auth/utils.ts` | Password hashing, token generation    |

## Public Interface

### Functions

\`\`\`typescript // Primary entry point for authentication async function
authenticate(credentials: Credentials): Promise<Session>

// Validate existing session function validateSession(token: string): boolean
\`\`\`

### Types

\`\`\`typescript interface Credentials { email: string; password: string; }

interface Session { userId: string; token: string; expiresAt: Date; } \`\`\`

## Dependencies

**Internal:**

- `src/db/users.ts` - User data access
- `src/crypto/hash.ts` - Password hashing

**External:**

- `jsonwebtoken` - JWT creation and validation
- `bcrypt` - Password hashing

## Consumers

- `src/api/routes/auth.ts` - REST API endpoints
- `src/graphql/resolvers/auth.ts` - GraphQL resolvers
- `src/middleware/auth.ts` - Request authentication

## Recent Changes

| Date       | Author | Change                      |
| ---------- | ------ | --------------------------- |
| 2024-01-10 | @alice | Add refresh token support   |
| 2024-01-05 | @bob   | Fix session expiration bug  |
| 2024-01-02 | @alice | Initial auth implementation |

## Key Code Snippets

### Session Creation

\`\`\`typescript async function createSession(user: User): Promise<Session> {
const token = jwt.sign( { userId: user.id }, process.env.JWT_SECRET, {
expiresIn: '24h' } );

return { userId: user.id, token, expiresAt: new Date(Date.now() + 24 * 60 *
60 * 1000) }; } \`\`\`

## Assumptions and Constraints

- Sessions expire after 24 hours
- Passwords must be hashed with bcrypt (cost factor 12)
- JWT_SECRET must be set in environment
- Database connection required for user lookup
```

## Gathering Techniques

### Finding Entry Points

```bash
# Find exports from a module
grep -r "export" src/auth/

# Find where module is imported
grep -r "from.*auth" src/

# Find test files
find . -name "*auth*.test.*"
```

### Understanding Dependencies

```bash
# Find imports in a file
grep "^import" src/auth/login.ts

# Find all files importing this module
grep -r "from.*auth" --include="*.ts" src/
```

### Recent History

```bash
# Recent commits for a file/directory
git log --oneline -10 -- src/auth/

# Who contributed most
git shortlog -sn -- src/auth/
```

## Quality Checklist

Before finalizing context:

- [ ] Purpose is clear and concise
- [ ] All key files are identified
- [ ] Public interface is documented
- [ ] Dependencies are mapped
- [ ] Consumers are identified
- [ ] Code snippets are relevant
- [ ] Recent history included
- [ ] No irrelevant details included

## See Also

- **Code review**: See [code-review](../code-review/) for reviewing gathered
  context
- **Documentation**: See [documentation-writing](../documentation-writing/) for
  using context in docs
