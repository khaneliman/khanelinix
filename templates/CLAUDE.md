# Project Templates

Flake-based project templates for quick development environment setup.

## Structure

```
templates/
└── {template-name}/
    ├── flake.nix          # Template flake
    ├── default.nix        # Package derivation (optional)
    └── shell.nix          # Dev shell (optional)
```

Templates are exposed via flake outputs and used with `nix flake init`.

## Available Templates

Run `nix flake show .#templates` to see all available templates.

Common templates: rust, python, node, go, c, cpp, dotnetf, angular

## Using Templates

```bash
# List templates
nix flake show github:khaneliman/khanelinix#templates

# Initialize new project from template
nix flake init -t github:khaneliman/khanelinix#rust

# Or from local repo
nix flake init -t .#rust
```

After initialization:

1. Update `pname` and `version` in derivation files
2. Add project-specific dependencies
3. Customize shell.nix with needed tools

## Creating New Templates

### 1. Create Directory

```bash
mkdir -p templates/my-template
cd templates/my-template
```

### 2. Write flake.nix

```nix
{
  description = "My Template Description";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forEachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./default.nix { };
      });

      devShells = forEachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix { };
      });
    };
}
```

### 3. Write default.nix (package)

```nix
{ stdenv, lib, ... }:
stdenv.mkDerivation {
  pname = "my-project";
  version = "0.0.1";
  src = ./.;

  buildPhase = ''
    # Build steps
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp program $out/bin/
  '';
}
```

### 4. Write shell.nix (dev environment)

```nix
{
  callPackage,
  mkShell,
  # Dev tools
  language-server,
  formatter,
  ...
}:
mkShell {
  inputsFrom = [ (callPackage ./default.nix { }) ];

  packages = [
    language-server
    formatter
  ];
}
```

### 5. Add to Flake Templates

Templates are auto-discovered by flake-parts from `templates/` directory.

### 6. Test Template

```bash
# Test initialization
cd /tmp
nix flake init -t ~/khanelinix#my-template

# Test build
nix build

# Test dev shell
nix develop
```

## Template Pattern

Multi-system support:

```nix
let
  systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
  forEachSystem = nixpkgs.lib.genAttrs systems;
in
{
  packages = forEachSystem (system: {
    default = /* ... */;
  });
}
```

Development shell:

```nix
mkShell {
  packages = [
    # Language tooling
    language-server
    formatter
    linter
  ];
}
```
