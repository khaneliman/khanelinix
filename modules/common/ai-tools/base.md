# Base AI Agent Instructions

Universal guidance for AI agents working with code across all projects.

## Core Principles

### 1. Planning First

- **Always plan before coding**: Identify files to modify, high-level changes,
  expected outcomes, and dependencies
- **Break down complex tasks** into manageable steps
- **Consider edge cases**: Error conditions, boundary cases, failure scenarios
- **Validate assumptions**: Ask for clarification when requirements are
  ambiguous

### 2. Code Quality

- **Read before writing**: Understand existing patterns, style, and conventions
  first
- **Follow existing conventions**: Match the style already present, even if you
  disagree
- **Minimize changes**: Smallest change that accomplishes the goal
- **Prefer refactoring to rewriting**: Improve code incrementally
- **Test your changes**: Run tests, linters, formatters before committing

### 3. Communication

- **Be explicit and precise** about what you're doing and why
- **Explain trade-offs** when making decisions
- **Ask when uncertain**: Don't guess or make assumptions
- **Document reasoning** for non-obvious decisions

### 4. Documentation

- **Minimalist comments**: Explain **why**, not **what**
  - Document complex algorithms or non-obvious logic
  - Highlight gotchas, workarounds, edge cases
  - Reference tickets/issues when relevant
- **Self-documenting code**: Clear names, small functions, avoid clever tricks
- **Keep docs updated** when changing code

## Development Workflow

### Phase 1: Understanding

1. Clarify the goal and desired outcome
2. Explore codebase to understand relevant code
3. Identify patterns and conventions
4. Check for existing solutions

### Phase 2: Planning

1. Create detailed plan with step-by-step approach
2. Identify risks and potential issues
3. Present plan for approval before proceeding
4. Incorporate user feedback

### Phase 3: Implementation

1. Follow the plan systematically
2. Make incremental progress, verify each step
3. Handle errors gracefully, update plan if needed
4. Test continuously after each change

### Phase 4: Verification

1. Run automated checks (tests, linters, formatters, builds)
2. Review changes with fresh eyes
3. Verify all requirements met
4. Check for unintended side effects

### Phase 5: Finalization

1. Clean up debugging code and unused imports
2. Update documentation to reflect current state
3. Prepare commit with clear message
4. Follow project commit conventions

## Code Style

- **Consistency over preference**: Follow existing style
- **Readability first**: Optimize for humans, not cleverness
- **Explicit over implicit**: Make intent clear
- **Simple over complex**: Choose straightforward solutions

### Naming

- Descriptive names that convey purpose
- Follow language conventions (camelCase, snake_case, etc.)
- Avoid abbreviations except well-established ones
- Use consistent terminology throughout

### Organization

- Group related code together
- Order logically (public before private, high-level before low-level)
- Minimize dependencies between modules
- Separate concerns into different files

### Error Handling

- Handle errors explicitly, don't suppress
- Fail fast: validate inputs early
- Provide helpful error messages with context
- Consider error recovery strategies

## Version Control

### Commits

- **Atomic commits**: One logical change per commit
- **Conventional Commits**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`,
  `chore:`
- **Clear messages**: Explain **why**, not **what**
- **Reference issues**: Link to relevant tickets/PRs

### Branching

- Follow project workflow (Git Flow, GitHub Flow, trunk-based)
- Descriptive branch names (feature/add-login, fix/memory-leak)
- One branch per feature/fix/task
- Stay synced with main branch

### Pull Requests

- Small, focused changes
- Descriptive title and context
- Include motivation, approach, testing notes
- Self-review before requesting reviews

## Testing

- Write tests for new code
- Update tests when changing behavior
- Test edge cases, not just happy path
- Use appropriate test types (unit, integration, e2e)

## Quality Checks

- Run formatters before committing
- Fix linting issues or document exceptions
- Check types in typed languages
- Review new dependencies for necessity

## Security

- **Never commit secrets**: API keys, passwords, credentials stay out of version
  control
- **Validate inputs**: Don't trust user input or external data
- **Follow security best practices**: Use established patterns for auth,
  authorization, data handling
- **Keep dependencies updated**: Patch security vulnerabilities
- **Consider privacy**: Handle user data responsibly

## Performance

- Profile before optimizing (measure actual bottlenecks)
- Only optimize code that matters for performance
- Consider scalability with larger datasets/higher load
- Balance optimization against readability/maintainability
