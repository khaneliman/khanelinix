# OpenCode permissions configuration module
# Defines permissions for bash commands and tools
_: {
  config = {
    programs.opencode.settings.permission = {
      edit = "ask";
      bash = {
        # Allow non-destructive git commands with wildcards
        "git status*" = "allow";
        "git log*" = "allow";
        "git diff*" = "allow";
        "git show*" = "allow";
        "git branch*" = "allow";
        "git remote*" = "allow";
        "git config*" = "allow";
        "git rev-parse*" = "allow";
        "git ls-files*" = "allow";
        "git ls-remote*" = "allow";
        "git describe*" = "allow";
        "git tag --list*" = "allow";
        "git blame*" = "allow";
        "git shortlog*" = "allow";
        "git reflog*" = "allow";
        "git add*" = "allow";

        # Safe Nix commands
        "nix search*" = "allow";
        "nix eval*" = "allow";
        "nix show-config*" = "allow";
        "nix flake show*" = "allow";
        "nix flake check*" = "allow";
        "nix log*" = "allow";

        # Side-effectful Nix execution stays on explicit ask.
        "nix build*" = "ask";
        "nix run*" = "ask";
        "nix shell*" = "ask";

        # Safe file system operations
        "ls*" = "allow";
        "pwd*" = "allow";
        "find*" = "allow";
        "grep*" = "allow";
        "rg*" = "allow";
        "cat*" = "allow";
        "head*" = "allow";
        "tail*" = "allow";
        "mkdir*" = "allow";
        "chmod*" = "allow";

        # Safe system info commands
        "systemctl list-units*" = "allow";
        "systemctl list-timers*" = "allow";
        "systemctl status*" = "allow";
        "journalctl*" = "allow";
        "dmesg*" = "allow";
        "env*" = "allow";
        "nh search*" = "allow";

        # Audio system (read-only)
        "pactl list*" = "allow";
        "pw-top*" = "allow";

        # Potentially destructive git commands
        "git reset*" = "ask";
        "git commit*" = "ask";
        "git push*" = "ask";
        "git pull*" = "ask";
        "git merge*" = "ask";
        "git rebase*" = "ask";
        "git checkout*" = "ask";
        "git switch*" = "ask";
        "git stash*" = "ask";

        # File deletion and modification
        "rm*" = "ask";
        # Phase 1 destructive-command baseline is ask for the explicit
        # primitives this surface can express directly.
        "rm -rf*" = "ask";
        "dd*" = "ask";
        "mkfs*" = "ask";
        "shutdown*" = "ask";
        "reboot*" = "ask";
        "mv*" = "ask";
        "cp*" = "ask";

        # System control mutation operations stay on explicit ask.
        # Keep the broader service-mutation verbs already in scope aligned here.
        "systemctl start*" = "ask";
        "systemctl stop*" = "ask";
        "systemctl restart*" = "ask";
        "systemctl reload*" = "ask";
        "systemctl enable*" = "ask";
        "systemctl disable*" = "ask";

        # Network operations
        "curl*" = "ask";
        "wget*" = "ask";
        "ping*" = "ask";
        "ssh*" = "ask";
        "scp*" = "ask";
        "rsync*" = "ask";

        # Package management
        "sudo*" = "ask";
        "nixos-rebuild*" = "ask";

        # Process management
        "kill*" = "ask";
        "killall*" = "ask";
        "pkill*" = "ask";
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
  };
}
