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
      "bypass"
    ];
    default = "standard";
    description = ''
      Permission profile for Claude Code operations:
      - conservative: Minimal permissions, most operations require confirmation
      - standard: Balanced permissions for normal development workflows
      - autonomous: Maximum autonomy for trusted environments
      - bypass: Start every session in bypassPermissions mode with no ask
        rules. Only the deny list and Claude Code's built-in root/home deletion
        circuit breaker still prompt. Intended for isolated hosts, containers,
        and VMs.

      Any profile can still enter bypassPermissions per session with the
      `claude-unsafe` alias; the profile only changes the default mode.
    '';
  };

  config = mkIf cfg.enable {
    programs.claude-code.settings.permissions =
      let
        # Base safe operations - always allowed regardless of profile
        baseAllow = [
          # Core Claude Code tools
          "Grep(*)"
          "LS(*)"
          "Read(*)"
          "Search(*)"
          "Task(*)"
          "TodoWrite(*)"
          "WebSearch"

          # Skill, command, and agent references live outside the project root
          # (the Claude configDir plus Nix store symlinks), so Read(*) - which is
          # scoped to the workspace - does not cover them.
          "Read(${config.home.homeDirectory}/.claude/**)"
          "Read(/nix/store/**)"

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
          "Bash(git ls-tree:*)"
          "Bash(git show-ref:*)"
          "Bash(git for-each-ref:*)"
          "Bash(git rev-list:*)"
          "Bash(git merge-base:*)"
          "Bash(git name-rev:*)"
          "Bash(git submodule status:*)"

          # Safe file system operations
          "Bash(ls:*)"
          # NOTE: find/fd are read-only by default but can run mutating
          # commands via -exec/-delete (find) or -x/-X (fd). Trusted here for
          # workflow smoothness; tighten if exposed to untrusted prompts.
          "Bash(find:*)"
          "Bash(fd:*)"
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
          "Bash(nl:*)"
          "Bash(tac:*)"
          "Bash(rev:*)"
          "Bash(tr:*)"
          # NOTE: -n suppresses default output and blocks in-place edits, but
          # `w`/`s///w`/`W` commands can still write a file. Obscure; kept for
          # parity with the codex allowlist.
          "Bash(sed -n:*)"

          # Safe read-only binary/hash inspection
          "Bash(od:*)"
          "Bash(xxd:*)"
          "Bash(hexdump:*)"
          "Bash(strings:*)"
          "Bash(base64:*)"
          "Bash(cksum:*)"
          "Bash(md5sum:*)"
          "Bash(sha1sum:*)"
          "Bash(sha256sum:*)"
          "Bash(sha512sum:*)"
          "Bash(b2sum:*)"

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
          "Bash(command -v:*)"
          "Bash(getconf:*)"
          "Bash(free:*)"
          "Bash(ps:*)"
          "Bash(pgrep:*)"
          "Bash(lsof:*)"
          "Bash(ss:*)"
          "Bash(lscpu)"
          "Bash(lscpu:*)"
          "Bash(lsblk:*)"
          "Bash(lsusb:*)"
          "Bash(lspci:*)"
          "Bash(findmnt:*)"
          "Bash(getent:*)"
          "Bash(groups)"
          "Bash(groups:*)"
          "Bash(locale)"
          "Bash(locale:*)"

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
          "Bash(nix store info:*)"
          "Bash(nix-instantiate --parse:*)"
          "Bash(nix-store -q:*)"
          "Bash(nix-store --query:*)"
          "Bash(nixos-option:*)"
          "Bash(statix check:*)"
          "Bash(nh search:*)"

          # Jujutsu read-only (jj-toolkit skill)
          "Bash(jj status:*)"
          "Bash(jj log:*)"
          "Bash(jj diff:*)"
          "Bash(jj show:*)"
          "Bash(jj evolog:*)"
          "Bash(jj op log:*)"
          "Bash(jj file list:*)"
          "Bash(jj bookmark list:*)"

          # GitHub CLI read-only (github-toolkit skill); gh api stays on ask
          # since it can mutate via -X POST/PATCH/DELETE.
          "Bash(gh pr view:*)"
          "Bash(gh pr list:*)"
          "Bash(gh pr diff:*)"
          "Bash(gh pr checks:*)"
          "Bash(gh pr status:*)"
          "Bash(gh issue view:*)"
          "Bash(gh issue list:*)"
          "Bash(gh issue status:*)"
          "Bash(gh run list:*)"
          "Bash(gh run view:*)"
          "Bash(gh repo view:*)"
          "Bash(gh release list:*)"
          "Bash(gh release view:*)"
          "Bash(gh label list:*)"
          "Bash(gh search:*)"

          # MCP tools - read only
          "mcp__bevy-brp__brp_type_guide"
          "mcp__code-review-graph__find_large_functions_tool"
          "mcp__code-review-graph__get_review_context_tool"
          "mcp__code-review-graph__list_repos_tool"
          "mcp__code-review-graph__semantic_search_nodes_tool"
          "mcp__github__search_repositories"
          "mcp__github__get_file_contents"
          "mcp__semble__find_related"
          "mcp__semble__search"
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

        # Ask rules are the strongest routine control Claude Code has: they beat
        # allow rules and force a prompt in *every* permission mode, including
        # acceptEdits, auto, and bypassPermissions. Permission rules also union
        # across settings scopes rather than override, so a session cannot drop
        # a user-settings ask rule with a flag or `--settings`.
        #
        # Consequence: only list a rule here when it tightens the profile's own
        # baseline mode. Anything the profile does not allow already prompts in
        # that baseline, so restating it buys no safety and permanently defeats
        # bypassPermissions. That is why `standard` (baseline `default`, which
        # prompts for every non-allowed Bash command) carries no ask rules.
        standardAsk = [ ];

        # `autonomous` runs with an acceptEdits baseline, which auto-approves
        # mkdir/touch/rm/rmdir/mv/cp/sed inside the working directory, and its
        # allow list adds `rm:*`. Recursive force deletion is the one primitive
        # that needs a human in that combination.
        autonomousAsk = [
          "Bash(rm -rf:*)"
        ];
      in
      {
        allow =
          if cfg.permissionProfile == "conservative" then
            baseAllow
          else if cfg.permissionProfile == "standard" then
            standardAllow
          else
            autonomousAllow; # autonomous and bypass

        ask =
          if cfg.permissionProfile == "conservative" then
            standardAllow # Conservative: ask for everything standard allows
          else if cfg.permissionProfile == "standard" then
            standardAsk
          else if cfg.permissionProfile == "autonomous" then
            autonomousAsk
          else
            [ ]; # bypass: no prompts beyond deny and the built-in circuit breaker

        # Deny is the only rule class that survives bypassPermissions without
        # prompting, so it carries the catastrophic-deletion circuit breaker.
        # Claude Code additionally prompts for `rm -rf /` and `rm -rf ~` in every
        # mode on its own.
        deny = [
          "Bash(rm -rf /*)"
          "Bash(rm -rf /)"
        ];

        defaultMode =
          if cfg.permissionProfile == "bypass" then
            "bypassPermissions"
          else if cfg.permissionProfile == "autonomous" then
            "acceptEdits"
          else
            "default";
      };
  };
}
