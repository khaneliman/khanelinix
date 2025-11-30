# AI Tools for Claude Code

This directory contains specialized agents, slash commands, and skills for
enhancing Claude Code's capabilities within this repository.

## Architecture Overview

```
ai-tools/
├── agents/        # Autonomous sub-processes with specialized tools
├── commands/      # Slash commands that expand to prompts
└── skills/        # Reusable knowledge and patterns
```

## Agents vs Commands vs Skills

### Agents (`agents/`)

**What:** Autonomous sub-processes with specialized tool access and state **When
to use:** Complex multi-step tasks requiring exploration and iteration
**Structure:** Markdown files with YAML frontmatter

**Pattern:**

```nix
{
  agent-name = ''
    ---
    name: Agent Display Name
    description: What this agent does
    ---

    [Agent prompt content with instructions]
  '';
}
```

**Categories:**

- `autonomous/`: Self-directed agents (builder, git-workflow, refactorer,
  scaffolder)
- `general/`: General purpose (code-reviewer, docs-writer, security-auditor)
- `nix/`: Nix specialists (flake-coder, nix-coder, nix-module-coder)
- `project/`: Project-specific (dotfiles-coder, system-planner, template-writer)

**Use agents for:**

- Code refactoring across multiple files
- Complex project scaffolding
- Multi-step workflows (build → test → commit)
- Tasks requiring exploration and discovery

### Commands (`commands/`)

**What:** Slash commands that expand to structured prompts **When to use:**
Single-invocation tasks with clear inputs **Structure:** Markdown with YAML
frontmatter defining arguments

**Pattern:**

```nix
{
  command-name = ''
    ---
    allowed-tools: Tool1, Tool2(*), Tool3(specific-arg:*)
    argument-hint: "[required-arg] [--optional-flag]"
    description: Brief command description
    ---

    [Command prompt with workflow steps]
  '';
}
```

**Categories:**

- `autonomous/`: Automated workflows (auto-build, auto-pr, validate-commit)
- `git/`: Git operations (commit-changes, review, conflict-resolve)
- `llm/`: Code analysis (explain-code, generate-tests, refactor-suggest)
- `nix/`: Nix operations (nix-check, module-scaffold, flake-update)
- `quality/`: Code quality (style-audit, dependency-audit, deep-check)
- `project/`: Project management (changelog)

**Use commands for:**

- Git commit message generation
- Code validation and checks
- Scaffolding new modules
- Quick code explanations

### Skills (`skills/`)

**What:** Reusable knowledge loaded on-demand by agents/commands **When to
use:** Domain knowledge needed by multiple agents **Structure:** Markdown
documentation and reference material

**Categories:**

- `anthropic/`: Official Anthropic skills (document-skills, mcp-builder, etc.)
- `khanelinix/`: Project-specific patterns (config-layering, theming,
  module-layout)
- `nix/`: Nix language patterns (conditionals, lib-usage, module-template)

**Use skills for:**

- Language-specific patterns
- Project architecture documentation
- Reference implementations
- Best practices documentation

## Creating New Agents

### 1. Choose the Right Category

- **Autonomous:** Self-managing workflows
- **General:** Broadly applicable tasks
- **Nix:** Nix/NixOS specific work
- **Project:** Repository-specific tasks

### 2. Define Agent Structure

```nix
# modules/common/ai-tools/agents/{category}/{name}.nix
{
  my-agent = ''
    ---
    name: My Agent
    description: One-line description of what agent does
    ---

    You are a specialized agent for [purpose].

    ## Core Mission
    [What this agent accomplishes]

    ## Workflow
    1. Step one
    2. Step two
    3. Step three

    ## Patterns to Follow
    - Pattern 1
    - Pattern 2

    ## Examples
    [Code examples]
  '';
}
```

### 3. Export in agents.nix

```nix
# modules/common/ai-tools/agents.nix
{
  # ... existing imports
  my-agent = (import ./agents/category/name.nix).my-agent;
}
```

### 4. Document in Root CLAUDE.md

Add to the "Specialized Agents" section in `/CLAUDE.md`.

## Creating New Commands

### 1. Choose the Right Category

- **autonomous:** Workflow automation
- **git:** Git operations
- **llm:** AI-powered code tasks
- **nix:** Nix-specific operations
- **quality:** Code quality checks
- **project:** Project management

### 2. Define Command Structure

```nix
# modules/common/ai-tools/commands/{category}/{name}.nix
{
  my-command = ''
    ---
    allowed-tools: Bash(*), Read, Edit, Write
    argument-hint: "[arg1] [arg2] [--flag]"
    description: Brief description
    ---

    ## Overview
    What this command does

    ## Workflow
    ### Phase 1: Preparation
    Steps...

    ### Phase 2: Execution
    Steps...

    ### Phase 3: Verification
    Steps...

    ## Examples
    /my-command arg1 arg2
  '';
}
```

### 3. Export in commands.nix

```nix
# modules/common/ai-tools/commands.nix
{
  # ... existing imports
  my-command = (import ./commands/category/name.nix).my-command;
}
```

### 4. Document in Root CLAUDE.md

Add to "Custom Commands" section in `/CLAUDE.md`.

## Creating New Skills

### 1. Identify Reusable Patterns

Skills should contain knowledge needed by multiple agents/commands.

### 2. Create Skill Directory

```bash
mkdir -p modules/common/ai-tools/skills/{category}/{skill-name}
```

### 3. Add Documentation

```markdown
# skills/{category}/{skill-name}/README.md

# Skill Name

## Purpose

What this skill teaches

## Patterns

### Pattern 1

[Description and example]

### Pattern 2

[Description and example]

## Usage

How agents/commands reference this skill
```

### 4. Reference in Agents/Commands

Agents can reference skills in their prompts:

```markdown
When working with X, follow patterns from skills/category/skill-name/
```

## Tool Restrictions (`allowed-tools`)

Commands can restrict which tools Claude can use:

**Syntax:**

- `Tool`: Allow tool with no arguments
- `Tool(*)`: Allow tool with any arguments
- `Tool(specific:*)`: Allow tool with specific pattern
- `Tool(arg1), Tool(arg2)`: Allow specific arguments

**Examples:**

```yaml
allowed-tools: Bash(nix build:*), Bash(nix eval:*), Read, Grep
# Allows: nix build, nix eval commands, Read any file, Grep any pattern
# Blocks: Other Bash commands, Write, Edit
```

**Best practices:**

- Be specific with Bash restrictions
- Allow Read/Grep for exploration
- Restrict Write/Edit unless necessary
- Use `Task` for complex multi-step work

## Testing Agents and Commands

### Agent Testing

```bash
# Use the Task tool to invoke agent
claude
> Use the my-agent agent to [task description]
```

### Command Testing

```bash
# Invoke command directly
claude
> /my-command arg1 arg2 --flag
```

### Validation Checklist

- [ ] Agent/command follows repository patterns
- [ ] Tool restrictions are appropriate
- [ ] Prompt is clear and actionable
- [ ] Examples are provided
- [ ] Exported in agents.nix/commands.nix
- [ ] Documented in root CLAUDE.md

## Common Patterns

### Multi-Phase Workflows

Structure commands/agents with clear phases:

```markdown
## Phase 1: Analysis

[Steps to analyze current state]

## Phase 2: Planning

[Steps to plan changes]

## Phase 3: Execution

[Steps to implement changes]

## Phase 4: Verification

[Steps to verify success]
```

### Error Handling

Include guidance for common errors:

```markdown
## Common Issues

### Issue 1: [Problem]

**Symptom:** [What user sees] **Cause:** [Why it happens] **Solution:** [How to
fix]
```

### Integration with Repository

Reference repository-specific patterns:

```markdown
## Repository Integration

- Follow khanelinix option naming: `khanelinix.*`
- Use lib functions from `modules/common/lib/`
- Apply theme from `config.khanelinix.user.theme`
```

## Maintenance

### Updating Agents/Commands

When repository patterns change:

1. Update affected agent/command prompts
2. Update examples in prompts
3. Test with representative tasks
4. Update root CLAUDE.md if interface changed

### Deprecating Agents/Commands

When removing:

1. Keep file with deprecation notice for 1-2 releases
2. Remove from exports in agents.nix/commands.nix
3. Remove from root CLAUDE.md documentation
4. Provide migration path if replaced

## Architecture Decisions

**Why separate agents/commands/skills?**

- **Agents:** Stateful, complex, multi-step (heavyweight)
- **Commands:** Stateless, focused, single-step (lightweight)
- **Skills:** Pure knowledge, no execution (documentation)

**Why Nix files instead of markdown?**

- Enables string manipulation in Nix
- Allows programmatic generation
- Maintains single source of truth
- Integrates with flake outputs

**Why YAML frontmatter?**

- Standard format for metadata
- Easy to parse in export functions
- Compatible with multiple AI tools
- Self-documenting

## Future Enhancements

Potential improvements:

- **Skill loading:** Automatic skill injection based on context
- **Agent composition:** Agents calling other agents
- **Command chaining:** Pipeline multiple commands
- **Telemetry:** Track which agents/commands are most used
- **Templates:** Scaffolding for new agents/commands
