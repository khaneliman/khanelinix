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
            # NOTE: avoid accidentally causing unexpected changes with default MCP and whitelist allow
            "--read-only"
            "stdio"
          ];
        };

        socket = {
          type = "http";
          url = "https://mcp.socket.dev/";
        };
      };

      settings = {
        theme = "dark";

        hooks = lib.importDir ./hooks { inherit pkgs; };

        permissions = {
          allow = [
            # Safe read-only git commands
            "Bash(git add:*)"
            "Bash(git status)"
            "Bash(git log:*)"
            "Bash(git diff:*)"
            "Bash(git show:*)"
            "Bash(git branch:*)"
            "Bash(git remote:*)"

            # Safe Nix commands (mostly read-only)
            "Bash(nix:*)"

            # Safe file system operations
            "Bash(ls:*)"
            "Bash(find:*)"
            "Bash(grep:*)"
            "Bash(rg:*)"
            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(mkdir:*)"
            "Bash(chmod:*)"

            # Safe system info commands
            "Bash(systemctl list-units:*)"
            "Bash(systemctl list-timers:*)"
            "Bash(systemctl status:*)"
            "Bash(journalctl:*)"
            "Bash(dmesg:*)"
            "Bash(env)"
            "Bash(claude --version)"
            "Bash(nh search:*)"

            # Audio system (read-only)
            "Bash(pactl list:*)"
            "Bash(pw-top)"

            # Core Claude Code tools
            "Glob(*)"
            "Grep(*)"
            "LS(*)"
            "Read(*)"
            "Search(*)"
            "Task(*)"
            "TodoWrite(*)"

            # Work MCP
            "mcp__mulesoft-analyzer"

            # GitHub tools (read-only)
            "mcp__github__search_repositories"
            "mcp__github__get_file_contents"

            # Safe web fetch from trusted domains
            "WebFetch(domain:wiki.hyprland.org)"
            "WebFetch(domain:github.com)"
            "WebFetch(domain:wiki.hypr.land)"
            "WebFetch(domain:raw.githubusercontent.com)"
          ];
          ask = [
            # Potentially destructive git commands
            "Bash(git checkout:*)"
            "Bash(git commit:*)"
            "Bash(git merge:*)"
            "Bash(git pull:*)"
            "Bash(git push:*)"
            "Bash(git rebase:*)"
            "Bash(git reset:*)"
            "Bash(git restore:*)"
            "Bash(git stash:*)"
            "Bash(git switch:*)"

            # File deletion and modification
            "Bash(cp:*)"
            "Bash(mv:*)"
            "Bash(rm:*)"

            # System control operations
            "Bash(systemctl disable:*)"
            "Bash(systemctl enable:*)"
            "Bash(systemctl mask:*)"
            "Bash(systemctl reload:*)"
            "Bash(systemctl restart:*)"
            "Bash(systemctl start:*)"
            "Bash(systemctl stop:*)"
            "Bash(systemctl unmask:*)"

            # Network operations
            "Bash(curl:*)"
            "Bash(ping:*)"
            "Bash(rsync:*)"
            "Bash(scp:*)"
            "Bash(ssh:*)"
            "Bash(wget:*)"

            # Package management
            "Bash(nixos-rebuild:*)"
            "Bash(sudo:*)"

            # Process management
            "Bash(kill:*)"
            "Bash(killall:*)"
            "Bash(pkill:*)"
          ];
          deny = [ ];
          defaultMode = "default";
        };
        model = "claude-sonnet-4-5";
        verbose = true;
        includeCoAuthoredBy = false;

        statusLine = {
          type = "command";
          command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
          padding = 0;
        };
      };

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) agents;

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) commands;

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) skills;

      memory.source = lib.getFile "modules/common/ai-tools/base.md";
    };
  };
}
