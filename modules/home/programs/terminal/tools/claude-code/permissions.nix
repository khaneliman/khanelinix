{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;

  cfg = config.khanelinix.programs.terminal.tools.claude-code;
in
{
  options.khanelinix.programs.terminal.tools.claude-code.permissionProfile = mkOption {
    type = types.enum [
      "conservative"
      "standard"
      "autonomous"
    ];
    default = "standard";
    description = ''
      Permission profile for Claude Code operations:
      - conservative: Minimal permissions, most operations require confirmation
      - standard: Balanced permissions for normal development workflows
      - autonomous: Maximum autonomy for trusted environments
    '';
  };

  config = mkIf cfg.enable {
    programs.claude-code.settings.permissions =
      let
        # Base safe operations - always allowed regardless of profile
        baseAllow = [
          # Core Claude Code tools
          "Glob(*)"
          "Grep(*)"
          "LS(*)"
          "Read(*)"
          "Search(*)"
          "Task(*)"
          "TodoWrite(*)"
          "WebSearch"

          # Safe read-only git commands
          "Bash(git status)"
          "Bash(git status:*)"
          "Bash(git log:*)"
          "Bash(git diff:*)"
          "Bash(git show:*)"
          "Bash(git branch:*)"
          "Bash(git remote:*)"
          "Bash(git blame:*)"
          "Bash(git ls-files:*)"
          "Bash(git rev-parse:*)"
          "Bash(git describe:*)"
          "Bash(git shortlog:*)"
          "Bash(git reflog:*)"
          "Bash(git cat-file:*)"
          "Bash(git grep:*)"
          "Bash(git stash list:*)"
          "Bash(git worktree list:*)"
          "Bash(git config --get:*)"
          "Bash(git config --list:*)"
          "Bash(git config -l)"

          # Safe file system operations
          "Bash(ls:*)"
          "Bash(find:*)"
          "Bash(cat:*)"
          "Bash(head:*)"
          "Bash(tail:*)"
          "Bash(pwd)"
          "Bash(stat:*)"
          "Bash(file:*)"
          "Bash(wc:*)"
          "Bash(tree:*)"
          "Bash(realpath:*)"
          "Bash(readlink:*)"
          "Bash(dirname:*)"
          "Bash(basename:*)"
          "Bash(du:*)"
          "Bash(df:*)"

          # Safe read-only text/data inspection
          "Bash(rg:*)"
          "Bash(grep:*)"
          "Bash(diff:*)"
          "Bash(sort:*)"
          "Bash(uniq:*)"
          "Bash(cut:*)"
          "Bash(comm:*)"
          "Bash(column:*)"
          "Bash(jq:*)"

          # Safe read-only system info
          "Bash(whoami)"
          "Bash(id)"
          "Bash(id:*)"
          "Bash(hostname)"
          "Bash(uname:*)"
          "Bash(date)"
          "Bash(date:*)"
          "Bash(uptime)"
          "Bash(env)"
          "Bash(printenv:*)"
          "Bash(which:*)"
          "Bash(type:*)"
          "Bash(free:*)"
          "Bash(ps:*)"

          # Safe nix read operations
          "Bash(nix eval:*)"
          "Bash(nix flake show:*)"
          "Bash(nix flake metadata:*)"
          "Bash(nix search:*)"
          "Bash(nix log:*)"
          "Bash(nix path-info:*)"
          "Bash(nix derivation show:*)"
          "Bash(nix why-depends:*)"
          "Bash(nix store ls:*)"
          "Bash(nix store cat:*)"
          "Bash(nix config show:*)"
          "Bash(nix show-config:*)"
          "Bash(nix registry list:*)"
          "Bash(nix profile list:*)"
          "Bash(nix-instantiate --parse:*)"
          "Bash(nh search:*)"

          # MCP tools - read only
          "mcp__github__search_repositories"
          "mcp__github__get_file_contents"
          "mcp__sequential-thinking__sequentialthinking"

          # Filesystem MCP - read operations
          "mcp__filesystem__read_file"
          "mcp__filesystem__read_text_file"
          "mcp__filesystem__read_media_file"
          "mcp__filesystem__read_multiple_files"
          "mcp__filesystem__list_directory"
          "mcp__filesystem__list_directory_with_sizes"
          "mcp__filesystem__directory_tree"
          "mcp__filesystem__search_files"
          "mcp__filesystem__get_file_info"
          "mcp__filesystem__list_allowed_directories"

          # Git MCP - read-only operations
          "mcp__git__git_status"
          "mcp__git__git_log"
          "mcp__git__git_diff"
          "mcp__git__git_diff_staged"
          "mcp__git__git_diff_unstaged"
          "mcp__git__git_show"
          "mcp__git__git_branch"

          # Fetch / Tavily MCP - read-only web
          "mcp__fetch__fetch"
          "mcp__tavily__tavily-search"
          "mcp__tavily__tavily-extract"
          "mcp__tavily__tavily-map"

          # Trusted web domains
          "WebFetch(domain:github.com)"
          "WebFetch(domain:wiki.hyprland.org)"
          "WebFetch(domain:wiki.hypr.land)"
          "WebFetch(domain:raw.githubusercontent.com)"
          "WebFetch(domain:snowfall.org)"
          "WebFetch(domain:devenv.sh)"
        ];

        # Standard profile additions - balanced permissions
        standardAllow = baseAllow ++ [
          # Git staging
          "Bash(git add:*)"

          # Nix evaluation/check (can trigger builds)
          "Bash(nix flake check:*)"

          # Directory creation
          "Bash(mkdir:*)"
          "Bash(chmod:*)"

          # System info
          "Bash(systemctl list-units:*)"
          "Bash(systemctl list-timers:*)"
          "Bash(systemctl status:*)"
          "Bash(journalctl:*)"
          "Bash(dmesg:*)"
          "Bash(claude --version)"

          # Audio system (read-only)
          "Bash(pactl list:*)"
          "Bash(pw-top)"

          # Hyprland
          "Bash(hyprctl dispatch:*)"

          # Sway
          "Bash(swaymsg:*)"
          "Bash(swaync-client:*)"
          "Bash(uwsm check:*)"

          # Debugging
          "Bash(coredumpctl list:*)"

          # Work MCP
          "mcp__mulesoft-analyzer"

          # Additional home directory reads
          "Read(${config.home.homeDirectory}/Documents/github/home-manager/**)"
          "Read(${config.home.homeDirectory}/.config/sway/**)"
        ];

        # Autonomous profile additions - full autonomy for trusted workflows
        autonomousAllow = standardAllow ++ [
          # Git write operations
          "Bash(git commit:*)"
          "Bash(git checkout:*)"
          "Bash(git switch:*)"
          "Bash(git stash:*)"
          "Bash(git restore:*)"
          "Bash(git reset:*)"

          # File operations
          "Bash(rm:*)"
        ];

        # Operations requiring confirmation in non-autonomous mode
        standardAsk = [
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
          # Phase 1 destructive-command baseline is ask for explicit primitives.
          "Bash(rm -rf:*)"
          "Bash(dd:*)"
          "Bash(mkfs:*)"
          "Bash(shutdown)"
          "Bash(shutdown:*)"
          "Bash(reboot)"
          "Bash(reboot:*)"

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
          "Bash(nix build:*)"
          "Bash(nix run:*)"
          "Bash(nix shell:*)"
          "Bash(nixos-rebuild:*)"
          "Bash(sudo:*)"

          # Process management
          "Bash(kill:*)"
          "Bash(killall:*)"
          "Bash(pkill:*)"

        ];

        # Autonomous mode still requires confirmation for these
        autonomousAsk = [
          # Always confirm pushing
          "Bash(git push:*)"
          "Bash(git merge:*)"
          "Bash(git rebase:*)"

          # System operations
          "Bash(systemctl:*)"
          "Bash(nix build:*)"
          "Bash(nix run:*)"
          "Bash(nix shell:*)"
          "Bash(nixos-rebuild:*)"
          "Bash(sudo:*)"

          # Network operations
          "Bash(curl:*)"
          "Bash(rsync:*)"
          "Bash(scp:*)"
          "Bash(ssh:*)"
          "Bash(wget:*)"

          # Process management
          "Bash(kill:*)"
          "Bash(killall:*)"
          "Bash(pkill:*)"

          # Keep destructive primitives on ask even for trusted profiles.
          "Bash(rm -rf:*)"
          "Bash(dd:*)"
          "Bash(mkfs:*)"
          "Bash(shutdown)"
          "Bash(shutdown:*)"
          "Bash(reboot)"
          "Bash(reboot:*)"
        ];
      in
      {
        allow =
          if cfg.permissionProfile == "autonomous" then
            autonomousAllow
          else if cfg.permissionProfile == "standard" then
            standardAllow
          else
            baseAllow;

        ask =
          if cfg.permissionProfile == "autonomous" then
            autonomousAsk
          else if cfg.permissionProfile == "standard" then
            standardAsk
          else
            standardAsk ++ standardAllow; # Conservative: ask for everything standard allows

        # Keep only catastrophic root deletion on deny; Phase 1 baseline for
        # the explicit destructive primitives is ask so Claude matches the repo
        # safety target without inventing broader deny parity.
        deny = [
          "Bash(rm -rf /*)"
          "Bash(rm -rf /)"
        ];

        defaultMode = if cfg.permissionProfile == "autonomous" then "acceptEdits" else "default";
      };
  };
}
