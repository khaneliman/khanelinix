{
  config = {
    programs.gemini-cli = {
      policies = {
        read-only-shell.rule = [
          {
            toolName = "run_shell_command";
            commandPrefix = [
              "ls "
              "find "
              "cat "
              "head "
              "tail "
              "rg "
              "grep "
              "type "
              "which "
              "whereis "
            ];
            decision = "allow";
            priority = 100;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "ls(\\s|$)";
            decision = "allow";
            priority = 100;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "git (status|diff|log|show|branch|remote|ls-files)(\\s|$)";
            decision = "allow";
            priority = 100;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "nix (eval|search|log|path-info)(\\s|$)";
            decision = "allow";
            priority = 100;
          }
        ];
        risky-shell.rule = [
          {
            toolName = "run_shell_command";
            commandPrefix = [
              "git add "
              "cp "
              "mv "
              "chmod "
              "chown "
              "curl "
              "wget "
              "ssh "
              "scp "
              "rsync "
              "nix build "
              "nix run "
              "nix shell "
              "nixos-rebuild "
              "darwin-rebuild "
              "nh "
              "kill "
              "killall "
              "pkill "
              "build-by-path "
              "why-depends "
            ];
            decision = "ask_user";
            priority = 200;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "git (commit|checkout|switch|restore|reset|stash|merge|rebase|pull|push)(\\s|$)";
            decision = "ask_user";
            priority = 200;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "fix-git(\\s|$)";
            decision = "ask_user";
            priority = 200;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "systemctl (start|stop|restart|reload|enable|disable)(\\s|$)";
            decision = "ask_user";
            priority = 200;
          }
        ];
        destructive-shell.rule = [
          # Phase 1 destructive-command baseline is ask, not deny parity.
          {
            toolName = "run_shell_command";
            commandPrefix = [
              "rm -rf "
              "sudo rm -rf "
            ];
            decision = "ask_user";
            priority = 300;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "(dd|mkfs)(\\s|$)";
            decision = "ask_user";
            priority = 300;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "(shutdown|reboot)(\\s|$)";
            decision = "ask_user";
            priority = 300;
          }
        ];
      };
    };
  };
}
