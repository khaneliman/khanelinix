---
name: scaffolding-modules
description: "khanelinix directory structure and module placement. Use when creating new modules, deciding where files belong, or understanding the modules/ organization. Covers platform separation (nixos/darwin/home/common) and auto-discovery."
---

# Module Layout

## Directory Structure

```
modules/
├── nixos/      # NixOS system-level (Linux only)
├── darwin/     # macOS system-level (nix-darwin)
├── home/       # Home Manager user-space (cross-platform)
└── common/     # Shared functionality (imported by others)
```

## Where to Place Modules

| Module Type            | Location          | Example                             |
| ---------------------- | ----------------- | ----------------------------------- |
| System service (Linux) | `modules/nixos/`  | `nixos/services/docker/`            |
| System service (macOS) | `modules/darwin/` | `darwin/services/yabai/`            |
| User application       | `modules/home/`   | `home/programs/terminal/tools/git/` |
| Cross-platform shared  | `modules/common/` | `common/ai-tools/`                  |

## Home Module Categories

```
modules/home/
├── programs/
│   ├── graphical/        # GUI applications
│   │   ├── browsers/
│   │   ├── editors/
│   │   └── tools/
│   └── terminal/         # CLI applications
│       ├── editors/
│       ├── shells/
│       └── tools/
├── services/             # User services
├── desktop/              # Desktop environment config
└── suites/               # Grouped functionality
```

## Auto-Discovery

Modules are automatically imported via `importModulesRecursive`:

- Place module files in appropriate directories
- No manual imports needed in most cases
- Enable modules via options system: `khanelinix.programs.*.enable = true`

## Common Module Import

Access common modules from platform-specific ones:

```nix
# In a home or nixos module
imports = [
  (lib.getFile "modules/common/shared-config")
];
```

## Creating a New Module Workflow

Copy this checklist when creating a new module:

```
Module Creation Progress:
- [ ] Step 1: Determine correct location (platform/category)
- [ ] Step 2: Create module file with standard structure
- [ ] Step 3: Define options under khanelinix namespace
- [ ] Step 4: Implement config with mkIf guard
- [ ] Step 5: Test module in isolation
- [ ] Step 6: Verify auto-discovery worked
- [ ] Step 7: Document in appropriate CLAUDE.md
```

### Step 1: Determine Location

Use the decision table above, or:

- Requires root? → `nixos/` or `darwin/`
- GUI app? → `home/programs/graphical/`
- CLI tool? → `home/programs/terminal/tools/`
- Cross-platform logic? → `common/`

### Step 2: Create File

```bash
# Example: new CLI tool
touch modules/home/programs/terminal/tools/mytool/default.nix
```

### Step 3-4: Standard Module Template

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.khanelinix.programs.terminal.tools.mytool;
in
{
  options.khanelinix.programs.terminal.tools.mytool = {
    enable = mkEnableOption "MyTool - brief description";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.mytool ];

    # Additional configuration...
  };
}
```

### Step 5: Test in Isolation

```bash
# Add to your home config temporarily
khanelinix.programs.terminal.tools.mytool.enable = true;

# Rebuild and test
home-manager switch --flake .
```

### Step 6: Verify Auto-Discovery

Check that the module was imported:

```bash
nix eval .#homeConfigurations.<user>@<host>.config.khanelinix.programs.terminal.tools.mytool.enable
# Should show: false (if not enabled) or true (if enabled)
```

### Step 7: Document

Update the appropriate CLAUDE.md file with your new module.

## Module Location Quick Reference

| I'm creating a...      | Platform | Category                    | Example Path                                         |
| ---------------------- | -------- | --------------------------- | ---------------------------------------------------- |
| System service (Linux) | nixos    | services                    | `nixos/services/docker/default.nix`                  |
| System service (macOS) | darwin   | services                    | `darwin/services/yabai/default.nix`                  |
| GUI application        | home     | programs/graphical          | `home/programs/graphical/apps/discord/default.nix`   |
| CLI tool               | home     | programs/terminal/tools     | `home/programs/terminal/tools/git/default.nix`       |
| Terminal emulator      | home     | programs/terminal/emulators | `home/programs/terminal/emulators/kitty/default.nix` |
| Shell configuration    | home     | programs/terminal/shells    | `home/programs/terminal/shells/zsh/default.nix`      |
| Editor                 | home     | programs/terminal/editors   | `home/programs/terminal/editors/neovim/default.nix`  |
| User service           | home     | services                    | `home/services/syncthing/default.nix`                |
| Feature bundle         | home     | suites                      | `home/suites/development/default.nix`                |
| Shared library code    | common   | lib                         | `common/lib/helpers.nix`                             |
| AI tools               | common   | ai-tools                    | `common/ai-tools/skills/my-skill/`                   |

## Quick Reference

- **System config?** → `nixos/` or `darwin/`
- **User app?** → `home/programs/`
- **Shared logic?** → `common/`
- **Desktop stuff?** → `home/desktop/`
- **Grouped features?** → `suites/`

## See Also

- **Option design**: See [designing-options](../designing-options/) for creating
  module options
- **Configuration layers**: See [configuring-layers](../configuring-layers/) for
  understanding where configs live
