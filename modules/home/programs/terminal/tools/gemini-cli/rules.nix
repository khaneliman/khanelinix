{
  config = {
    programs.gemini-cli = {
      policies = {
        read-only-shell.rule = [
          {
            toolName = "run_shell_command";
            commandPrefix = [
              "ls "
              # NOTE: find/fd are read-only by default but can run mutating
              # commands via -exec/-delete (find) or -x/-X (fd). Trusted here
              # for workflow smoothness; tighten if exposed to untrusted input.
              "find "
              "fd "
              "cat "
              "head "
              "tail "
              "rg "
              "grep "
              "diff "
              "sort "
              "uniq "
              "cut "
              "comm "
              "column "
              "jq "
              "nl "
              "tac "
              "rev "
              "tr "
              # NOTE: -n suppresses default output and blocks in-place edits,
              # but `w`/`s///w`/`W` commands can still write a file. Obscure;
              # kept for parity with the codex allowlist.
              "sed -n "
              "od "
              "xxd "
              "hexdump "
              "strings "
              "base64 "
              "cksum "
              "md5sum "
              "sha1sum "
              "sha256sum "
              "sha512sum "
              "b2sum "
              "stat "
              "file "
              "wc "
              "tree "
              "realpath "
              "readlink "
              "dirname "
              "basename "
              "du "
              "type "
              "which "
              "whereis "
              "command -v "
              "getconf "
              "printenv "
              "lsof "
              "getent "
              "lsblk "
              "lsusb "
              "lspci "
              "findmnt "
              "nixos-option "
              "statix check "
            ];
            decision = "allow";
            priority = 100;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "(ls|pwd|whoami|id|hostname|uname|date|uptime|env|free|ps|pgrep|ss|df|groups|locale|lscpu)(\\s|$)";
            decision = "allow";
            priority = 100;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "git (status|diff|log|show|branch|remote|ls-files|ls-tree|blame|grep|rev-parse|describe|shortlog|reflog|cat-file|show-ref|for-each-ref|rev-list|merge-base|name-rev|stash list|worktree list|submodule status|config (--get|--list|-l))(\\s|$)";
            decision = "allow";
            priority = 100;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "nix (eval|search|log|path-info|flake (show|metadata)|derivation show|why-depends|store (ls|cat|info)|config show|show-config|registry list|profile list)(\\s|$)";
            decision = "allow";
            priority = 100;
          }
          {
            toolName = "run_shell_command";
            commandRegex = "(nh search|nix-instantiate --parse|nix-store (-q|--query))(\\s|$)";
            decision = "allow";
            priority = 100;
          }
          # Read-only jj (jj-toolkit skill)
          {
            toolName = "run_shell_command";
            commandRegex = "jj (status|log|diff|show|evolog|op log|file list|bookmark list)(\\s|$)";
            decision = "allow";
            priority = 100;
          }
          # Read-only gh (github-toolkit skill); gh api stays unlisted since it
          # can mutate via -X POST/PATCH/DELETE.
          {
            toolName = "run_shell_command";
            commandRegex = "gh (auth status|pr (view|list|diff|checks|status)|issue (view|list|status)|run (view|list)|repo view|release (view|list)|label list|search)(\\s|$)";
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
