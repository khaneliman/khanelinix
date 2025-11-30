# Common Modules Context

Cross-platform shared modules used by both NixOS and nix-darwin systems.

## Module Categories

### AI Tools (`ai-tools/`)

Claude Code agents, slash commands, and skills for this repository.

**Patterns:**

- Agents: Specialized sub-agents for complex tasks (Nix refactor, module
  scaffolding, etc.)
- Commands: Slash commands that expand to prompts (`/nix-check`,
  `/commit-changes`, etc.)
- Skills: Reusable skill definitions

**When adding new agents/commands:**

- Follow existing pattern in `agents/` or `commands/`
- Export via `default.nix`
- Document in root `CLAUDE.md` specialized agents section

### Nix Utilities (`nix/`)

Nix language helpers, custom lib functions, and build utilities.

**Patterns:**

- Pure functions for configuration generation
- Reusable abstractions to reduce repetition
- Use `lib.` prefix for all lib functions

### Programs (`programs/`)

Application configurations shared across platforms.

**Patterns:**

- Generic configs that work on both NixOS and macOS
- Terminal tools, shells, editors
- Platform-specific overrides in `modules/nixos/programs/` or
  `modules/darwin/programs/`

### Suites (`suites/`)

Configuration bundles that enable multiple related modules.

**Examples:**

- `common`: Base system tools and utilities
- Development environments (if they exist)

**Pattern:**

```nix
{
  khanelinix.suites.common.enable = true;
  # Enables: git, ssh, essential CLI tools, etc.
}
```

### System (`system/`)

System-level shared configuration (fonts, localization, etc.).

**Patterns:**

- Font definitions used by stylix and applications
- Cross-platform system settings

## Theming

**Prefer module-specific theme customizations over stylix defaults.**

When adding themed elements:

1. Check if module has khanelinix theme options
2. Use conditional paths based on theme:
   `if theme == "catppuccin-mocha" then ...`
3. Fallback to stylix only when no module-specific option exists

## Option Design

All options follow `khanelinix.{category}.{subcategory}.{option}` structure.

**Example:**

```nix
khanelinix.programs.terminal.tools.claude-code.enable = true;
```

**Reduce repetition:**

```nix
# Good: Shared top-level option
khanelinix.user.theme = "catppuccin-mocha";
# Then use: config.khanelinix.user.theme throughout

# Bad: Duplicating theme string in every module
```
