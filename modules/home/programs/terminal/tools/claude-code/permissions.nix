{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;

  cfg = config.khanelinix.programs.terminal.tools.claude-code;

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

    # Safe read-only git commands
    "Bash(git status)"
    "Bash(git log:*)"
    "Bash(git diff:*)"
    "Bash(git show:*)"
    "Bash(git branch:*)"
    "Bash(git remote:*)"

    # Safe file system operations
    "Bash(ls:*)"
    "Bash(find:*)"
    "Bash(cat:*)"
    "Bash(head:*)"
    "Bash(tail:*)"

    # Safe nix read operations
    "Bash(nix eval:*)"
    "Bash(nix flake show:*)"
    "Bash(nix flake metadata:*)"

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

    # All nix commands
    "Bash(nix:*)"

    # Directory creation
    "Bash(mkdir:*)"
    "Bash(chmod:*)"

    # Search tools
    "Bash(rg:*)"
    "Bash(grep:*)"

    # System info
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

  # Autonomous mode still requires confirmation for these
  autonomousAsk = [
    # Always confirm pushing
    "Bash(git push:*)"
    "Bash(git merge:*)"
    "Bash(git rebase:*)"

    # System operations
    "Bash(systemctl:*)"
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
  ];

  # Never allowed - dangerous operations
  denyList = [
    "Bash(rm -rf /*)"
    "Bash(rm -rf /)"
    "Bash(dd:*)"
    "Bash(mkfs:*)"
  ];
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
    programs.claude-code.settings.permissions = {
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

      deny = denyList;

      defaultMode = if cfg.permissionProfile == "autonomous" then "acceptEdits" else "default";
    };
  };
}
