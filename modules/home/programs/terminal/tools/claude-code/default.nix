{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.tools.claude-code;
in
{
  options.khanelinix.programs.terminal.tools.claude-code = {
    enable = mkEnableOption "Claude Code configuration";
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;

      mcpServers = {
        github = {
          type = "stdio";
          command = lib.getExe pkgs.github-mcp-server;
          args = [
            "stdio"
          ];
          env = {
            GITHUB_PERSONAL_ACCESS_TOKEN = "$GITHUB_TOKEN";
          };
        };

        socket = {
          type = "http";
          url = "https://mcp.socket.dev/";
        };
      };

      settings = {
        theme = "dark";
        permissions = {
          allow = [
            "Bash(git*)"
            "Bash(nix*)"
            "Bash(ls*)"
            "Bash(find*)"
            "Bash(grep*)"
            "Bash(rg*)"
            "Bash(cat*)"
            "Bash(head*)"
            "Bash(tail*)"
            "Bash(mkdir*)"
            "Bash(chmod*)"
            "Bash(systemctl*)"
            "Bash(journalctl*)"
            "Bash(dmesg*)"
            "Bash(env)"
            "Edit(*)"
            "Read(*)"
            "Write(*)"
            "Glob(*)"
            "Grep(*)"
            "LS(*)"
            "Task(*)"
            "TodoWrite(*)"
            "MultiEdit(*)"
            "NotebookEdit(*)"
            "BashOutput(*)"
            "KillBash(*)"
            "ExitPlanMode(*)"
            "mcp__*"
          ];
          ask = [
            "WebFetch(*)"
            "WebSearch(*)"
            "Bash(curl*)"
            "Bash(wget*)"
            "Bash(ping*)"
            "Bash(ssh*)"
            "Bash(scp*)"
            "Bash(rsync*)"
          ];
          deny = [ ];
          defaultMode = "plan";
        };
        model = "claude-sonnet-4-20250514";
        verbose = true;
        includeCoAuthoredBy = false;

        statusLine = {
          type = "command";
          command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
          padding = 0;
        };
      };

      agents = {
        code-reviewer = ''
          ---
          name: code-reviewer
          description: Specialized code review agent for development tasks
          tools: Read, Edit, Grep, Bash
          ---

          You are a senior software engineer specializing in code reviews.
          Focus on:
          - Code quality and best practices
          - Security vulnerabilities
          - Performance optimizations
          - Maintainability and readability
          - Following project conventions

          Always provide constructive feedback with specific suggestions for improvement.
        '';

        nix-expert = ''
          ---
          name: Nix Expert
          description: Nix and NixOS configuration specialist
          tools: Read, Edit, Grep, Bash
          ---

          You are a Nix expert specializing in NixOS configurations and Nix expressions.
          Focus on:
          - Nix language best practices
          - NixOS module system
          - Package management
          - Flakes and input management
          - Build systems and derivations

          Always follow functional programming principles and Nix conventions.
        '';

        documentation = ''
          ---
          name: Documenter
          description: Technical documentation and README writer
          tools: Read, Write, Edit, Grep
          ---

          You are a technical writer who creates clear, comprehensive documentation.
          Focus on:
          - User-friendly explanations
          - Clear examples and usage
          - Proper markdown formatting
          - Comprehensive but concise content
          - Accessibility and readability

          Always include practical examples and keep documentation up-to-date.
        '';
      };

      commands = {
        changelog = ''
          ---
          allowed-tools: Bash(git log:*), Bash(git diff:*), Edit, Read
          argument-hint: [version] [change-type] [message]
          description: Update CHANGELOG.md with new entry following conventional commit standards
          ---

          Parse the version, change type, and message from the input
          and update the CHANGELOG.md file accordingly following
          conventional commit standards.
        '';

        review = ''
          ---
          allowed-tools: Bash(git status:*), Bash(git diff:*), Read, Grep
          description: Analyze staged git changes and provide thorough code review
          ---

          Analyze the staged git changes and provide a thorough
          code review with suggestions for improvement, focusing on
          code quality, security, and maintainability.
        '';

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

        commit-msg = ''
          ---
          allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*)
          description: Generate conventional commit message based on staged changes
          ---

          Generate a conventional commit message based on the
          staged changes, following the project's commit standards.
        '';

        commit-changes = ''
          ---
          allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
          description: Analyze changes, stage them in atomic chunks, and commit with conventional messages
          ---

          Analyze all unstaged changes and group them into logical, atomic commits.
          For each chunk:
          1. Stage only the relevant files/changes for that logical unit
          2. Generate an appropriate conventional commit message
          3. Create the commit

          Consider these grouping strategies:
          - By feature/functionality (new features together)
          - By file type/area (config changes, docs, tests)
          - By scope (same module/component changes)
          - By change type (fixes, refactoring, etc.)

          Ensure each commit is atomic and follows conventional commit standards.
        '';
      };
    };
  };
}
