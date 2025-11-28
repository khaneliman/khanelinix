{
  nix-validation = ''
    ---
    name: nix-validation
    description: "Comprehensive Nix validation: treefmt-nix integration, statix/deadnix linting, flake checks, khanelinix-specific patterns. Use when validating Nix code or setting up linting infrastructure."
    ---

    # Nix Validation & Linting

    ## Tool Overview

    | Tool | Purpose | Speed |
    |------|---------|-------|
    | `nix-instantiate --parse` | Syntax check only | Instant |
    | `nixfmt` | Official formatter (RFC-style) | Fast |
    | `statix` | Linter for anti-patterns | Fast |
    | `deadnix` | Find unused code | Fast |
    | `nix flake check` | Full evaluation + checks | Slow |

    ## treefmt-nix Integration

    The recommended way to combine all tools:

    ```nix
    # flake.nix
    {
      inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

      outputs = { self, nixpkgs, treefmt-nix, ... }:
        let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.''${system};
          treefmtEval = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;  # or nixfmt-rfc-style
              deadnix.enable = true;
              statix.enable = true;
            };
          };
        in {
          formatter.''${system} = treefmtEval.config.build.wrapper;
          checks.''${system}.formatting = treefmtEval.config.build.check self;
        };
    }
    ```

    ## Statix Lints (Anti-Patterns)

    | Lint | Issue | Fix |
    |------|-------|-----|
    | `bool_comparison` | `x == true` | Just use `x` |
    | `empty_let_in` | `let in expr` | Remove let-in |
    | `eta_reduction` | `x: f x` | Just use `f` |
    | `manual_inherit` | `x = x;` | Use `inherit x;` |
    | `manual_inherit_from` | `x = a.x;` | Use `inherit (a) x;` |
    | `legacy_let_syntax` | `let { x = 1; body = x; }` | Use `let x = 1; in x` |
    | `unquoted_uri` | `https://...` | Quote the URI |
    | `useless_parens` | `(expr)` when not needed | Remove parens |

    ```bash
    # Check for anti-patterns
    statix check .

    # Auto-fix what's possible
    statix fix .

    # Ignore specific lint
    # Add to file: # statix: ignore manual_inherit
    ```

    ## Deadnix (Unused Code)

    ```bash
    # Find unused bindings
    deadnix .

    # Auto-remove unused code
    deadnix -e .

    # Check specific patterns
    deadnix --no-lambda-arg .  # Keep unused lambda args
    deadnix --no-lambda-pattern-names .  # Keep pattern names
    ```

    **Common False Positives:**
    - `self` in flake outputs (hide with `...`)
    - `_` prefixed variables (intentionally unused)
    - Module arguments used in imports

    ## khanelinix-Specific Validation

    ```bash
    # Validate module options follow namespace
    nix eval .#nixosModules.default --apply 'm: builtins.attrNames (m {} { lib = (import <nixpkgs> {}).lib; config = {}; pkgs = {}; }).options.khanelinix or {}'

    # Check home-manager module
    nix build .#homeConfigurations.khaneliman.activationPackage --dry-run

    # Verify darwin configuration
    nix build .#darwinConfigurations.khaneliman.system --dry-run

    # Test specific host
    nix build .#nixosConfigurations.khanelinux.config.system.build.toplevel --dry-run
    ```

    ## Module Validation Patterns

    ```nix
    # Check option types are correct
    nix eval --expr '
      let
        pkgs = import <nixpkgs> {};
        module = import ./modules/mymodule.nix;
        result = pkgs.lib.evalModules {
          modules = [ module ];
        };
      in result.options
    '

    # Verify module doesn't have evaluation errors
    nix eval --expr '
      let
        pkgs = import <nixpkgs> {};
        lib = pkgs.lib;
      in import ./path/to/module.nix { inherit lib pkgs; config = {}; }
    '
    ```

    ## Common Nix Errors & Fixes

    | Error | Cause | Fix |
    |-------|-------|-----|
    | `syntax error, unexpected ';'` | Missing value before `;` | Check previous line for missing `=` |
    | `undefined variable 'lib'` | Not in scope | Add `{ lib, ... }:` to function args |
    | `infinite recursion encountered` | Self-reference in `rec` | Use `let` bindings or `self` pattern |
    | `attribute 'x' missing` | Wrong path or typo | Check attr names, use `or default` |
    | `cannot coerce set to string` | Using attrset as string | Use specific attr or `builtins.toJSON` |
    | `function expects 1 arguments` | Missing argument | Check function signature |
    | `called with unexpected argument` | Extra arg in call | Check function accepts arg |

    ## Flake Check Integration

    ```nix
    # Add custom checks to flake
    checks.''${system} = {
      # Formatting check
      formatting = treefmtEval.config.build.check self;

      # Module evaluation check
      module-eval = pkgs.runCommand "check-modules" {} '''
        ''${pkgs.nix}/bin/nix-instantiate --eval --strict \
          ''${self}/modules/test.nix
        touch $out
      ''';

      # Pre-commit hooks
      pre-commit = pre-commit-hooks.lib.''${system}.run {
        src = ./.;
        hooks = {
          nixfmt.enable = true;
          statix.enable = true;
          deadnix.enable = true;
        };
      };
    };
    ```

    ## Quick Validation Commands

    ```bash
    # Fastest: syntax only
    nix-instantiate --parse file.nix > /dev/null

    # Fast: format + lint
    nixfmt --check . && statix check . && deadnix .

    # Project formatter (treefmt)
    nix fmt

    # Full check (slow but thorough)
    nix flake check

    # Git-aware (staged only)
    git diff --cached --name-only | grep '\.nix$' | xargs -r nixfmt --check
    ```

    ## Pre-Commit Hook (Nix)

    ```nix
    # In devShell
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [ nixfmt statix deadnix ];
      shellHook = '''
        # Git pre-commit hook
        cat > .git/hooks/pre-commit << 'EOF'
        #!/bin/sh
        files=$(git diff --cached --name-only | grep '\.nix$')
        [ -z "$files" ] && exit 0
        echo "$files" | xargs nixfmt --check || exit 1
        echo "$files" | xargs statix check || exit 1
        echo "$files" | xargs deadnix || exit 1
        EOF
        chmod +x .git/hooks/pre-commit
      ''';
    };
    ```

    ## Troubleshooting

    | Issue | Solution |
    |-------|----------|
    | `nix flake check` slow | Use `--no-build` for eval-only |
    | statix false positive | Add `# statix: ignore` comment |
    | deadnix removes needed code | Use `--no-lambda-arg` flag |
    | nixfmt changes too much | Pin to specific version |
    | IFD errors in check | Use `--impure` (carefully) |
  '';
}
