{
  nix-validation = ''
    ---
    name: nix-validation
    description: "Fast Nix syntax and format validation. Use when checking .nix files before commits, after edits, or when nix evaluation errors occur."
    ---

    # Nix Validation

    ## Quick Checks

    ```bash
    # Syntax check (instant)
    nix-instantiate --parse file.nix

    # Format check
    nixfmt --check file.nix

    # Project formatter (uses treefmt)
    nix fmt
    ```

    ## Flake Validation

    ```bash
    # Full flake check
    nix flake check

    # Eval without build (faster)
    nix eval .#nixosConfigurations.hostname.config.system.build.toplevel

    # Check specific output
    nix eval .#packages.x86_64-linux.default
    ```

    ## Git-Aware

    ```bash
    # Check only staged .nix files
    git diff --cached --name-only --diff-filter=d | grep '\.nix$' | xargs -r nixfmt --check

    # Check modified files
    git diff --name-only | grep '\.nix$' | xargs -r nix-instantiate --parse
    ```

    ## Common Errors

    | Error | Likely Cause |
    |-------|--------------|
    | "syntax error, unexpected" | Missing semicolon, bracket, or quote |
    | "undefined variable" | Typo or missing inherit/import |
    | "infinite recursion" | Self-referential attribute or rec issue |
    | "attribute missing" | Wrong path or typo in attr access |

    ## Pre-Commit Workflow

    ```bash
    nix fmt && nix flake check
    ```
  '';
}
