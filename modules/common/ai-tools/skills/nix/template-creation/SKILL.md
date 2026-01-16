---
name: template-creation
description: Create development environment templates and project scaffolding with Nix flakes. Use when creating new project templates, setting up dev shells, configuring language-specific environments, or integrating with CI/CD.
---

# Template Creation Guide

Expert guidance for creating comprehensive development environment templates
with Nix flakes.

## Core Principles

1. **Reproducibility** - Same template produces identical environments
   everywhere
2. **Developer experience** - Fast to use, easy to understand
3. **Language-specific best practices** - Follow conventions for each ecosystem
4. **Integration-ready** - Works with editors, CI/CD, containers
5. **Maintainability** - Easy to update dependencies and configurations

## Template Creation Workflow

Copy this checklist when creating templates:

```
Template Creation Progress:
- [ ] Step 1: Identify target language/framework requirements
- [ ] Step 2: Design flake structure and inputs
- [ ] Step 3: Create devShell with all needed tools
- [ ] Step 4: Add language-specific configuration files
- [ ] Step 5: Configure editor/IDE integration
- [ ] Step 6: Add CI/CD configuration
- [ ] Step 7: Write documentation
- [ ] Step 8: Test on clean system
```

## Flake Template Structure

### Basic Template Layout

```
template/
├── flake.nix           # Main flake definition
├── flake.lock          # Locked dependencies
├── .envrc              # direnv integration
├── .gitignore          # Git ignore patterns
├── README.md           # Documentation
└── src/                # Source code placeholder
```

### Standard flake.nix Template

```nix
{
  description = "Project description";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Add development tools here
          ];

          shellHook = ''
            echo "Development environment loaded"
          '';
        };

        # Optional: packages, apps, etc.
      }
    );
}
```

## Language-Specific Templates

### Node.js/TypeScript

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_20
    nodePackages.npm
    nodePackages.typescript
    nodePackages.typescript-language-server
  ];

  shellHook = ''
    export PATH="$PWD/node_modules/.bin:$PATH"
  '';
};
```

Configuration files to include:

- `tsconfig.json` - TypeScript configuration
- `package.json` - Package manifest
- `.prettierrc` - Code formatting
- `.eslintrc.js` - Linting rules

### Python

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    python311
    python311Packages.pip
    python311Packages.virtualenv
    python311Packages.black
    python311Packages.mypy
    pyright
  ];

  shellHook = ''
    # Create venv if it doesn't exist
    if [ ! -d .venv ]; then
      python -m venv .venv
    fi
    source .venv/bin/activate
  '';
};
```

Configuration files to include:

- `pyproject.toml` - Project configuration
- `requirements.txt` or `poetry.lock` - Dependencies
- `.python-version` - Python version

### Rust

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt
  ];

  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
};
```

Configuration files to include:

- `Cargo.toml` - Package manifest
- `rust-toolchain.toml` - Toolchain version
- `.rustfmt.toml` - Formatting rules

### Go

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    go
    gopls
    golangci-lint
    delve
  ];

  shellHook = ''
    export GOPATH="$PWD/.go"
    export PATH="$GOPATH/bin:$PATH"
  '';
};
```

## Editor Integration

### VS Code

`.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "nix.enableLanguageServer": true,
  "nix.serverPath": "nil"
}
```

### direnv (.envrc)

```bash
use flake
```

## CI/CD Integration

### GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v25
        with:
          nix_path: nixpkgs=channel:nixos-unstable
      - uses: cachix/cachix-action@v14
        with:
          name: your-cache
      - run: nix build
      - run: nix flake check
```

## Template Quality Checklist

- [ ] `nix flake check` passes
- [ ] DevShell includes all required tools
- [ ] Editor integration configured
- [ ] CI/CD workflow included
- [ ] README with setup instructions
- [ ] `.gitignore` covers generated files
- [ ] License file included
- [ ] Works on Linux and macOS

## Common Patterns

### Multi-Shell Template

```nix
devShells = {
  default = pkgs.mkShell {
    # Default development environment
  };

  ci = pkgs.mkShell {
    # Minimal CI environment
  };

  full = pkgs.mkShell {
    # Full environment with optional tools
  };
};
```

### Cross-Platform Considerations

```nix
buildInputs = with pkgs; [
  # Common tools
  git
  jq
] ++ lib.optionals stdenv.isDarwin [
  # macOS-specific
  darwin.apple_sdk.frameworks.Security
] ++ lib.optionals stdenv.isLinux [
  # Linux-specific
  inotify-tools
];
```

## See Also

- **Flake management**: See [managing-flakes](../managing-flakes/) for input and
  lock file management
- **Writing Nix**: See [writing-nix](../writing-nix/) for Nix code best
  practices
- **Module scaffolding**: See
  [scaffolding-modules](../../khanelinix/scaffolding-modules/) for NixOS module
  templates
