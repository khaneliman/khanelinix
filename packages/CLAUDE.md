# Custom Packages

Custom package derivations for khanelinix configuration.

## Structure

```
packages/
└── {package-name}/
    └── package.nix        # Package derivation
```

Packages are auto-discovered by flake-parts and exposed as
`pkgs.khanelinix.{package-name}`.

## When to Create a Package Here

**Create a package in `packages/` when:**

- Completely custom derivation used in your config (wallpapers, scripts,
  helpers)
- Complex derivation that's nearly impossible to write as an overlay
- Permanent custom package specific to khanelinix

**Use an overlay instead when:**

- Overriding existing nixpkgs package
- Patching upstream package
- Changing build flags on existing package

## Building and Testing

```bash
# Build package
nix build .#my-tool

# Run without building system
nix run .#my-tool

# Test the result
./result/bin/my-tool

# Check what's in the package
ls -la result/
```

## Using in Configuration

Packages are available as `pkgs.khanelinix.{package-name}`:

```nix
# In any module
home.packages = [ pkgs.khanelinix.my-tool ];

# Or directly
programs.some-program.package = pkgs.khanelinix.my-tool;
```
