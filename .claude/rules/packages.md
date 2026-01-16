---
paths:
  - "packages/**"
  - "templates/**"
---

# Packages and Templates

Custom package derivations and flake templates for khanelinix.

## packages/

Custom package derivations exposed as `pkgs.khanelinix.{name}`.

### When to Create Package vs Overlay vs Module

**Create in packages/ when:**

- New custom derivation (wallpapers, scripts, utilities)
- Doesn't exist in nixpkgs
- Permanent custom tool for your environment
- Complex build requiring its own derivation

**Use overlay instead when:**

- Overriding existing nixpkgs package
- Patching upstream package
- Changing build flags of existing package
- Version pinning upstream packages

**Use module instead when:**

- Simple script that doesn't need building
- Configuration file generation
- One-off tool specific to single module

### Usage in Modules

```nix
# In any module
{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.khanelinix.my-tool ];

  # Or in system configuration
  environment.systemPackages = [ pkgs.khanelinix.my-script ];
}
```

### Testing

```bash
# Build package
nix build .#my-tool

# Run directly
nix run .#my-tool

# Check what's in output
nix build .#my-tool && ls -la result/

# Enter dev shell with package available
nix shell .#my-tool
```

## templates/

Flake-based project templates for common development patterns.

### When to Create Templates

**Create template when:**

- Reusable project structure you create often
- Common language/framework setup (Rust, Python, Go, etc.)
- Development environment with consistent tooling
- Project type with specific requirements

**Don't create template when:**

- One-off project structure
- Simple enough to copy manually
- Better served by upstream template

### Template Structure

```
templates/rust/
├── flake.nix           # Flake with package and devShell
├── default.nix         # Package derivation
├── shell.nix           # Dev shell (optional, for non-flake users)
├── .envrc              # direnv integration
└── src/
    └── main.rs
```

### Template flake.nix Pattern

```nix
{
  description = "Rust project template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, pkgs, ... }: {
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "my-rust-app";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rustc
            cargo
            rust-analyzer
            rustfmt
          ];
        };
      };
    };
}
```

### Template Metadata

Templates are defined in root flake.nix:

```nix
# flake.nix
{
  templates = {
    rust = {
      path = ./templates/rust;
      description = "Rust project with Nix flake";
      welcomeText = ''
        # Rust Project Template

        Run `nix develop` to enter the dev shell.
        Run `nix build` to build the project.
      '';
    };
  };
}
```

### Using Templates

```bash
# List available templates
nix flake show .#templates

# Initialize new project from template
nix flake init -t .#rust

# Or from GitHub
nix flake init -t github:khaneliman/khanelinix#rust

# Preview template
nix flake show github:khaneliman/khanelinix#templates.rust
```

### Template Best Practices

- **Include .envrc** - Enable direnv for automatic dev shell loading
- **Provide examples** - Include sample code demonstrating the setup
- **Document in welcomeText** - Explain first steps after initialization
- **Pin dependencies** - Use specific nixpkgs commits for reproducibility
- **Support multiple systems** - Linux, macOS (aarch64 and x86_64)
- **Minimal by default** - Users can add more later

### Template Testing

```bash
# Test template initialization
cd $(mktemp -d)
nix flake init -t ~/khanelinix#rust
nix develop
nix build
```
