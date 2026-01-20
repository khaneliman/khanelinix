---
name: documentation-writing
description: Generate comprehensive technical documentation including READMEs, API docs, user guides, and changelogs. Use when creating project documentation, documenting APIs, writing user guides, or maintaining changelogs.
---

# Documentation Writing Guide

Creates clear, comprehensive technical documentation that serves both newcomers
and experienced users.

## Core Principles

1. **User-focused** - Write for the audience, not yourself
2. **Actionable** - Provide steps users can follow immediately
3. **Accurate** - Test all examples against current code
4. **Scannable** - Use clear structure for quick navigation
5. **Maintained** - Keep documentation current with code changes

## Documentation Workflow

Copy this checklist when writing documentation:

```
Documentation Progress:
- [ ] Step 1: Identify target audience and their needs
- [ ] Step 2: Analyze codebase for key concepts
- [ ] Step 3: Outline document structure
- [ ] Step 4: Write content with examples
- [ ] Step 5: Test all code examples
- [ ] Step 6: Review for clarity and completeness
- [ ] Step 7: Add cross-references and links
```

## README Structure

### Essential Sections

```markdown
# Project Name

Brief description (1-2 sentences)

## Features

- Key feature 1
- Key feature 2

## Quick Start

\`\`\`bash

# Installation

npm install project-name

# Basic usage

project-name --help \`\`\`

## Installation

Detailed installation instructions...

## Usage

### Basic Usage

...

### Advanced Usage

...

## Configuration

| Option   | Default | Description    |
| -------- | ------- | -------------- |
| `--flag` | `false` | Does something |

## Contributing

Guidelines for contributors...

## License

MIT - see LICENSE file
```

### README Quality Checklist

- [ ] Title clearly identifies the project
- [ ] Description explains what it does in one sentence
- [ ] Installation works on a fresh system
- [ ] Quick start gets users running in < 5 minutes
- [ ] All code examples are tested and current
- [ ] Configuration options are documented
- [ ] Links to related documentation work

## API Documentation

### Function Documentation Format

```typescript
/**
 * Calculates the total price including tax.
 *
 * @param items - Array of items with price property
 * @param taxRate - Tax rate as decimal (e.g., 0.08 for 8%)
 * @returns Total price with tax applied
 * @throws {Error} If items array is empty
 *
 * @example
 * const total = calculateTotal([{price: 10}, {price: 20}], 0.08);
 * // Returns: 32.40
 */
function calculateTotal(items: Item[], taxRate: number): number {
  // implementation
}
```

### Documentation Elements

| Element         | When to Include                   |
| --------------- | --------------------------------- |
| **Description** | Always - what the function does   |
| **Parameters**  | Always - type and purpose of each |
| **Returns**     | Always - what comes back          |
| **Throws**      | When errors are possible          |
| **Example**     | Always - realistic usage          |
| **Since**       | For versioned APIs                |
| **Deprecated**  | When replacing functionality      |

## User Guides

### Guide Structure

1. **Getting Started**
   - Prerequisites
   - Installation
   - First success (quick win)
   - Common gotchas

2. **Core Concepts**
   - Key terminology
   - How things work
   - Mental model

3. **How-To Guides**
   - Task-focused tutorials
   - Step-by-step instructions
   - Expected outcomes

4. **Reference**
   - Complete option lists
   - API reference
   - Configuration reference

5. **Troubleshooting**
   - Common errors and fixes
   - FAQ
   - Getting help

### Writing Style

**Do:**

- Use active voice ("Run the command" not "The command should be run")
- Start with the goal ("To deploy to production, run...")
- Include expected output
- Provide alternatives when relevant

**Don't:**

- Assume prior knowledge without stating prerequisites
- Skip steps that seem "obvious"
- Use jargon without explanation
- Write walls of text without structure

## Changelog Format

### Keep a Changelog Standard

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- New feature description

### Changed

- Modified behavior description

### Fixed

- Bug fix description

## [1.0.0] - 2024-01-15

### Added

- Initial release features

### Security

- Security fix description

[Unreleased]: https://github.com/user/repo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

### Change Categories

| Category       | Use When                          |
| -------------- | --------------------------------- |
| **Added**      | New features                      |
| **Changed**    | Changes to existing functionality |
| **Deprecated** | Features to be removed            |
| **Removed**    | Removed features                  |
| **Fixed**      | Bug fixes                         |
| **Security**   | Security vulnerability fixes      |

### Changelog Best Practices

- Write for users, not developers
- Include migration instructions for breaking changes
- Link to issues/PRs for context
- Use semantic versioning consistently
- Keep entries concise but informative

## Documentation Anti-Patterns

### Don't: Write for yourself

```markdown
# Bad

The frobnicator uses a modified Dijkstra algorithm with O(n log n) complexity
for path optimization.
```

### Do: Write for users

```markdown
# Good

The route finder calculates the fastest path between locations. For most routes,
results appear in under 1 second.
```

### Don't: Skip the basics

```markdown
# Bad

Run `npm start` to begin.
```

### Do: Include context

```markdown
# Good

## Starting the Development Server

Run the development server to see your changes in real-time:

\`\`\`bash npm start \`\`\`

This starts a server at http://localhost:3000. Changes to source files
automatically reload the browser.
```

## See Also

- **Specifications**: See [specifications](../specifications/) for requirement
  documentation
- **Code review**: See [code-review](../code-review/) for reviewing
  documentation in PRs
