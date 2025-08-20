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

      agents = import ./agents.nix;

      commands = import ./commands.nix;
    };
  };
}
