{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.tools.opencode;
in
{
  options.khanelinix.programs.terminal.tools.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      settings = {
        theme = "opencode";
        model = "anthropic/claude-sonnet-4-20250514";
        autoshare = false;
        autoupdate = false;

        permission = {
          edit = "ask";
          bash = {
            # Safe read-only git commands
            "git status" = "allow";
            "git log" = "allow";
            "git diff" = "allow";
            "git show" = "allow";
            "git branch" = "allow";
            "git remote" = "allow";
            "git add" = "allow";

            # Safe Nix commands
            "nix search" = "allow";
            "nix eval" = "allow";
            "nix show-config" = "allow";
            "nix flake show" = "allow";
            "nix flake check" = "allow";

            # Safe file system operations
            "ls" = "allow";
            "pwd" = "allow";
            "find" = "allow";
            "grep" = "allow";
            "rg" = "allow";
            "cat" = "allow";
            "head" = "allow";
            "tail" = "allow";
            "mkdir" = "allow";
            "chmod" = "allow";

            # Safe system info commands
            "systemctl list-units" = "allow";
            "systemctl list-timers" = "allow";
            "systemctl status" = "allow";
            "journalctl" = "allow";
            "dmesg" = "allow";
            "env" = "allow";
            "nh search" = "allow";

            # Audio system (read-only)
            "pactl list" = "allow";
            "pw-top" = "allow";

            # Potentially destructive git commands
            "git reset" = "ask";
            "git commit" = "ask";
            "git push" = "ask";
            "git pull" = "ask";
            "git merge" = "ask";
            "git rebase" = "ask";
            "git checkout" = "ask";
            "git switch" = "ask";
            "git stash" = "ask";

            # File deletion and modification
            "rm" = "ask";
            "mv" = "ask";
            "cp" = "ask";

            # System control operations
            "systemctl start" = "ask";
            "systemctl stop" = "ask";
            "systemctl restart" = "ask";
            "systemctl reload" = "ask";
            "systemctl enable" = "ask";
            "systemctl disable" = "ask";

            # Network operations
            "curl" = "ask";
            "wget" = "ask";
            "ping" = "ask";
            "ssh" = "ask";
            "scp" = "ask";
            "rsync" = "ask";

            # Package management
            "sudo" = "ask";
            "nixos-rebuild" = "ask";

            # Process management
            "kill" = "ask";
            "killall" = "ask";
            "pkill" = "ask";
          };
          read = "allow";
          list = "allow";
          glob = "allow";
          grep = "allow";
          webfetch = "ask";
          write = "ask";
          task = "allow";
          todowrite = "allow";
          todoread = "allow";
        };

        formatter = {
          nixfmt = {
            command = [
              (lib.getExe pkgs.nixfmt)
              "$FILE"
            ];
            extensions = [ ".nix" ];
          };

          csharpier = {
            command = [
              (lib.getExe pkgs.csharpier)
              "$FILE"
            ];
            extensions = [
              ".cs"
            ];
          };

          rustfmt = {
            command = [
              (lib.getExe pkgs.rustfmt)
              "$FILE"
            ];
            extensions = [ ".rs" ];
          };
        };

        # FIXME: seems to cause opencode to just hang
        mcp = {
          github = {
            type = "local";
            command = [
              (lib.getExe pkgs.github-mcp-server)
              "--read-only"
              "stdio"
            ];
            enabled = false;
          };

          socket = {
            type = "remote";
            url = "https://mcp.socket.dev/";
            enabled = false;
          };
        };
      };

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) agents;

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) commands;
    };
  };
}
