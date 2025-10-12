# Base AI Agent Instructions

This file provides universal guidance for AI agents when working with code in
any project. These principles apply across all programming languages,
frameworks, and development environments.

## Core Principles

### 1. Planning First

- **Always plan before coding**: Create a clear plan that includes:
  - Files to modify or create
  - High-level changes and their rationale
  - Expected outcomes and potential side effects
  - Dependencies and prerequisites
- **Break down complex tasks**: Decompose large tasks into smaller, manageable
  steps
- **Consider edge cases**: Think through error conditions, boundary cases, and
  failure scenarios
- **Validate assumptions**: Confirm your understanding with the user when
  requirements are ambiguous

### 2. Code Quality

- **Read before writing**: Always read existing code to understand patterns,
  style, and conventions before making changes
- **Follow existing conventions**: Match the style, structure, and patterns
  already present in the codebase
- **Minimize changes**: Make the smallest possible change that accomplishes the
  goal
- **Prefer refactoring to rewriting**: Improve existing code incrementally
  rather than replacing it wholesale
- **Test your changes**: Run tests, linters, and formatters before committing

### 3. Communication

- **Be explicit and precise**: Clearly communicate what you're doing and why
- **Explain trade-offs**: When making decisions, articulate the alternatives
  considered
- **Ask when uncertain**: Don't guess or make assumptions - ask for
  clarification
- **Document reasoning**: Capture the "why" behind non-obvious decisions

### 4. Documentation

- **Minimalist comments**: Use comments sparingly and strategically:
  - Explain **why**, not **what** (the code shows what)
  - Document complex algorithms or non-obvious logic
  - Highlight gotchas, workarounds, or edge cases
  - Reference tickets, issues, or external documentation when relevant
- **Self-documenting code**: Write clear, readable code that speaks for itself:
  - Use descriptive variable and function names
  - Keep functions small and focused
  - Avoid clever tricks that sacrifice clarity
- **Keep documentation up to date**: Update comments and docs when changing code

## Development Workflow

### Phase 1: Understanding

1. **Clarify the goal**: Ensure you understand the user's request and desired
   outcome
2. **Explore the codebase**: Use search and read tools to understand relevant
   code
3. **Identify patterns**: Note conventions, architectural patterns, and style
   guidelines
4. **Check for existing solutions**: Look for similar implementations or related
   functionality

### Phase 2: Planning

1. **Create a detailed plan**: Outline your approach step-by-step
2. **Identify risks**: Note potential issues, breaking changes, or complexities
3. **Present for approval**: Share your plan with the user before proceeding
4. **Incorporate feedback**: Adjust based on user input

### Phase 3: Implementation

1. **Follow the plan**: Implement changes systematically according to your plan
2. **Make incremental progress**: Complete and verify each step before moving to
   the next
3. **Handle errors gracefully**: Address issues as they arise, updating your
   plan if needed
4. **Test continuously**: Verify functionality after each significant change

### Phase 4: Verification

1. **Run automated checks**: Execute tests, linters, formatters, and build
   processes
2. **Review your changes**: Read through your modifications with fresh eyes
3. **Verify completeness**: Ensure all requirements are met
4. **Check for side effects**: Confirm no unintended consequences

### Phase 5: Finalization

1. **Clean up**: Remove debugging code, temporary files, and unused imports
2. **Update documentation**: Ensure comments and docs reflect current state
3. **Prepare commit**: Stage changes and write a clear commit message
4. **Follow project conventions**: Use the project's commit format and
   procedures

## Code Style Guidelines

### General Principles

- **Consistency over preference**: Follow existing style even if you disagree
  with it
- **Readability first**: Optimize for human readers, not clever solutions
- **Explicit over implicit**: Make intent clear rather than relying on implicit
  behavior
- **Simple over complex**: Choose the straightforward solution unless complexity
  is justified

### Naming Conventions

- **Be descriptive**: Names should clearly convey purpose and intent
- **Follow language conventions**: Use idiomatic naming for the language (e.g.,
  camelCase in JavaScript, snake_case in Python)
- **Avoid abbreviations**: Use full words unless abbreviations are
  well-established (e.g., `id`, `url`)
- **Use consistent terminology**: Use the same terms for the same concepts
  throughout the codebase

### Code Organization

- **Group related code**: Keep related functions, types, and constants together
- **Order logically**: Arrange code in a logical reading order (e.g., public
  before private, high-level before low-level)
- **Minimize dependencies**: Reduce coupling between modules and components
- **Separate concerns**: Keep different responsibilities in different
  files/modules

### Error Handling

- **Handle errors explicitly**: Don't ignore or suppress errors
- **Fail fast**: Validate inputs and fail early when requirements aren't met
- **Provide context**: Include helpful error messages with relevant information
- **Consider recovery**: Think about how errors can be recovered from or
  reported to users

## Version Control Best Practices

### Commits

- **Atomic commits**: Each commit should represent a single logical change
- **Conventional Commits**: Follow the Conventional Commits specification:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation changes
  - `refactor:` for code refactoring
  - `test:` for test changes
  - `chore:` for maintenance tasks
- **Clear messages**: Write descriptive commit messages that explain **why**,
  not **what**
- **Reference issues**: Link to relevant issues, tickets, or pull requests

### Branching

- **Follow project workflow**: Use the branching strategy defined by the project
  (Git Flow, GitHub Flow, trunk-based, etc.)
- **Descriptive branch names**: Use clear, hyphenated names that describe the
  work
- **Keep branches focused**: One branch per feature, bug fix, or task
- **Stay up to date**: Regularly sync with the main branch to avoid conflicts

### Pull Requests

- **Small, focused PRs**: Keep changes small and focused on a single purpose
- **Descriptive titles**: Clearly state what the PR accomplishes
- **Provide context**: Include motivation, approach, and testing notes in the
  description
- **Self-review**: Review your own changes before requesting reviews from others

## Testing and Quality Assurance

### Testing Approach

- **Write tests for new code**: Cover new functionality with appropriate tests
- **Update tests for changes**: Modify existing tests when changing behavior
- **Test edge cases**: Don't just test the happy path
- **Use appropriate test types**: Unit tests for logic, integration tests for
  interactions, e2e tests for workflows

### Quality Checks

- **Run formatters**: Apply automated formatting before committing
- **Run linters**: Fix linting issues or document why they should be ignored
- **Check types**: Ensure type safety in typed languages
- **Review dependencies**: Verify new dependencies are necessary and appropriate

## Security Considerations

- **Never commit secrets**: Keep API keys, passwords, and credentials out of
  version control
- **Validate inputs**: Don't trust user input or external data
- **Follow security best practices**: Use established security patterns for
  authentication, authorization, and data handling
- **Keep dependencies updated**: Regularly update dependencies to patch security
  vulnerabilities
- **Consider privacy**: Handle user data responsibly and in compliance with
  regulations

## Performance Considerations

- **Profile before optimizing**: Measure performance to identify actual
  bottlenecks
- **Optimize wisely**: Only optimize code that matters for performance
- **Consider scalability**: Think about how code will perform with larger
  datasets or higher load
- **Balance trade-offs**: Consider the cost of optimization against readability
  and maintainability

## Continuous Improvement

- **Learn from feedback**: Incorporate code review feedback into future work
- **Refactor opportunistically**: Improve code quality when touching existing
  code
- **Share knowledge**: Document learnings and insights for future reference
- **Stay current**: Keep up with language, framework, and tool updates

## Project-Specific Instructions

This file provides universal guidelines. Always look for project-specific
instructions in:

- `CONTRIBUTING.md` - Contribution guidelines
- `README.md` - Project overview and setup instructions
- `CLAUDE.md` - Project-specific AI agent instructions
- `.github/PULL_REQUEST_TEMPLATE.md` - PR requirements
- Style guides and linting configurations

**Always prioritize project-specific instructions over these general
guidelines.**
