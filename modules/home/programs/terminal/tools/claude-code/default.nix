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

        hooks =
          let
            notify =
              title: message:
              if pkgs.stdenv.hostPlatform.isDarwin then
                ''osascript -e 'display notification "${message}" with title "${title}"' ''
              else
                ''notify-send '${title}' '${message}' '';
          in
          {
            SessionStart = [
              {
                matcher = "*";
                hooks = [
                  {
                    type = "command";
                    command = ''
                      echo '=== Git Status ==='
                      git status
                      echo '\n=== Recent Commits ==='
                      git log --oneline -5
                      echo '\n=== Jujutsu Status ==='
                      jj status 2>/dev/null
                      echo '\n=== Current Jujutsu Change ==='
                      jj log -r @ --no-graph 2>/dev/null || echo 'Not a jujutsu repository'
                    '';
                  }
                ];
              }
            ];

            Notification = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = notify "Claude Code" "Awaiting your input";
                  }
                ];
              }
            ];

            SubagentStop = [
              {
                matcher = "*";
                hooks = [
                  {
                    type = "command";
                    command = ''
                      agent_type=$(cat | jq -r '.subagent_type // "Unknown"')
                      ${
                        if pkgs.stdenv.hostPlatform.isDarwin then
                          ''osascript -e "display notification \"Subagent completed: $agent_type\" with title \"Claude Code\""''
                        else
                          ''notify-send 'Claude Code' "Subagent completed: $agent_type"''
                      }
                    '';
                  }
                ];
              }
            ];

            PreCompact = [
              {
                matcher = "*";
                hooks = [
                  {
                    type = "command";
                    command = ''
                      mkdir -p ~/.local/share/claude-code/context-backups
                      backup_file="$HOME/.local/share/claude-code/context-backups/compact-$(date +%Y%m%d-%H%M%S).log"
                      echo "=== Context Compaction at $(date) ===" >> "$backup_file"
                      echo "Working Directory: $(pwd)" >> "$backup_file"
                      echo "Git Status:" >> "$backup_file"
                      git status --short 2>/dev/null >> "$backup_file" || echo "Not a git repository" >> "$backup_file"
                    '';
                  }
                ];
              }
            ];

            SessionEnd = [
              {
                matcher = "*";
                hooks = [
                  {
                    type = "command";
                    command = ''
                      mkdir -p ~/.local/share/claude-code/sessions
                      session_log="$HOME/.local/share/claude-code/sessions/$(date +%Y-%m).log"
                      echo "=== Session End: $(date) ===" >> "$session_log"
                      echo "Directory: $(pwd)" >> "$session_log"
                      git status --short 2>/dev/null >> "$session_log" || echo "Not a git repository" >> "$session_log"
                      echo "" >> "$session_log"
                    '';
                  }
                ];
              }
            ];
          };

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
            "Bash(git reset:*)"
            "Bash(git commit:*)"
            "Bash(git push:*)"
            "Bash(git pull:*)"
            "Bash(git merge:*)"
            "Bash(git rebase:*)"
            "Bash(git checkout:*)"
            "Bash(git switch:*)"
            "Bash(git stash:*)"

            # File deletion and modification
            "Bash(rm:*)"
            "Bash(mv:*)"
            "Bash(cp:*)"

            # System control operations
            "Bash(systemctl start:*)"
            "Bash(systemctl stop:*)"
            "Bash(systemctl restart:*)"
            "Bash(systemctl reload:*)"
            "Bash(systemctl enable:*)"
            "Bash(systemctl disable:*)"
            "Bash(systemctl mask:*)"
            "Bash(systemctl unmask:*)"

            # Network operations
            "Bash(curl:*)"
            "Bash(wget:*)"
            "Bash(ping:*)"
            "Bash(ssh:*)"
            "Bash(scp:*)"
            "Bash(rsync:*)"

            # Package management
            "Bash(sudo:*)"
            "Bash(nixos-rebuild:*)"

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
    };
  };
}
