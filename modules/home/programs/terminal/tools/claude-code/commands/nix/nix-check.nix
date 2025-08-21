{
  nix-check = ''
    ---
    allowed-tools: Bash(nix flake check:*), Bash(nix fmt), Read, Grep
    description: Check Nix configuration for issues and suggest optimizations
    ---

    Check the current Nix configuration for issues:
    - Run nix flake check
    - Validate syntax and formatting
    - Check for unused imports
    - Suggest optimizations
  '';
}
