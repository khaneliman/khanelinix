{
  lib-usage = ''
    ---
    name: nix-lib-usage
    description: "Nix library usage patterns: with, inherit, and inline lib. prefixes. Use when deciding how to access lib functions, avoiding the with lib anti-pattern, or writing analysis-friendly Nix code."
    ---

    # Library Usage Patterns

    ## The Rule

    > Avoid high-scope `with lib;` - it breaks static analysis for all nested code

    ## Decision Guide

    | Situation | Pattern |
    |-----------|---------|
    | 1-2 lib functions | Inline `lib.` prefix |
    | 3+ lib functions | `inherit (lib) ...` in let |
    | Single-line list | `with pkgs; [...]` is OK |
    | Module-level scope | NEVER use `with lib;` |

    ## Inline Prefix (1-2 uses)

    ```nix
    config = lib.mkIf cfg.enable {
      setting = lib.mkDefault "value";
    };
    ```

    ## Inherit Pattern (3+ uses)

    ```nix
    let
      inherit (lib) mkIf mkEnableOption mkOption types;
      cfg = config.namespace.module;
    in
    {
      # Now use directly: mkIf, types.str, etc.
    }
    ```

    ## Acceptable Single-Line With

    ```nix
    # OK - tightly scoped to single expression
    environment.systemPackages = with pkgs; [ git vim curl ];

    # OK - limited scope
    meta = with lib; { license = licenses.mit; };
    ```

    ## Anti-Pattern: High-Scope With

    ```nix
    # WRONG - breaks analysis for everything inside
    { config, lib, pkgs, ... }:
    with lib;
    {
      # IDE can't help, shadowing bugs, unclear origins
    }
    ```

    ## Why This Matters

    - Static analyzers (nixd, nil) lose visibility
    - IDE auto-completion breaks
    - Shadowing bugs become possible
    - Code origins unclear in nested expressions
  '';
}
