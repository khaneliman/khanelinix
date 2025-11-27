{
  module-layout = ''
    ---
    name: khanelinix-module-layout
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

    | Module Type | Location | Example |
    |-------------|----------|---------|
    | System service (Linux) | `modules/nixos/` | `nixos/services/docker/` |
    | System service (macOS) | `modules/darwin/` | `darwin/services/yabai/` |
    | User application | `modules/home/` | `home/programs/terminal/tools/git/` |
    | Cross-platform shared | `modules/common/` | `common/ai-tools/` |

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

    ## Quick Reference

    - **System config?** → `nixos/` or `darwin/`
    - **User app?** → `home/programs/`
    - **Shared logic?** → `common/`
    - **Desktop stuff?** → `home/desktop/`
    - **Grouped features?** → `suites/`
  '';
}
