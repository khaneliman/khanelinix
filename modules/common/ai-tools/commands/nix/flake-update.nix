let
  commandName = "flake-update";
  description = "Comprehensive flake input management and update workflow";
  allowedTools = "Bash(nix flake update*), Bash(nix flake lock*), Bash(nix flake show*), Bash(git*), Read, Grep";
  argumentHint = "[input...] [--commit] [--test] [--interactive]";
  prompt = ''
    Safely update flake inputs while maintaining system stability.

    **Workflow:**

    1. **Input Analysis - Assess Current State**:
       - Run `nix flake metadata` to show current input versions and lock status
       - Use `nix flake show` to verify current flake structure
       - Identify which inputs have updates available
       - Check flake.lock for any obvious issues or conflicts

    2. **Selective Updates - Update Strategically**:
       - If specific inputs are provided as arguments, update only those using `nix flake lock --update-input <input>`
       - If no arguments given, update all inputs with `nix flake update`
       - After each update, use `git diff flake.lock` to show what changed
       - Document the changes for each input (old version -> new version)

    3. **Testing and Validation - Ensure Stability**:
       - Run `nix flake check` to verify the flake evaluates correctly
       - Test key configurations by attempting to build main outputs
       - Check that templates still work if --test is specified
       - Report any evaluation errors or build failures

    4. **Documentation and Commit**:
       - Generate a summary of all changes made
       - Note any breaking changes or issues discovered
       - If --commit is specified, create a descriptive commit message following the repository's conventions
       - If --interactive is specified, ask for confirmation before each major step

    **Command Arguments:**
    - [input...]: Update only these specific inputs (e.g., nixpkgs, home-manager)
    - --commit: Automatically commit the update with a descriptive message
    - --test: Run comprehensive tests including template builds
    - --interactive: Ask for confirmation before each step

    Always summarize changes clearly and avoid updating inputs unnecessarily.
  '';

in
{
  ${commandName} = {
    inherit
      commandName
      description
      allowedTools
      argumentHint
      prompt
      ;
  };
}
