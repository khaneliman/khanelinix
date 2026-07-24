{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.khanelinix.programs.terminal.tools.claude-code;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") {
    gatewayEnabled = config.khanelinix.services.cliproxyapi.enable or false;
    inherit lib pkgs;
  };
  hooks = lib.zipAttrsWith (_: values: lib.concatLists values) (
    lib.importFiles ./hooks {
      inherit
        aiTools
        config
        lib
        pkgs
        ;
    }
  );

  claudeIcon = ./assets/claude.ico;

  # Codex-style status line: model+reasoning, session/worktree, context, limits.
  # Rate-limit fields only appear for Claude.ai subscribers, so guard for null.
  statusLineScript = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      input=$(cat)
      jq -r '
        def pc(v): (v // 0) | floor | tostring;
        (.model.display_name // "?") as $name |
        (.session_name // "") as $session |
        (.worktree.branch // .workspace.git_worktree // "") as $branch |
        ( "[" + $name
          + (if ((.model.id // "") | test("\\[1m\\]")) and (($name | ascii_downcase) | test("1m") | not)
             then " ·1M" else "" end)
          + (if (.effort.level // "") != "" then " " + .effort.level else "" end)
          + (if .thinking.enabled == true then " +think" else "" end)
          + "]" )
        + " 📁 " + (((.workspace.current_dir // .cwd // "") | split("/") | last))
        + (if $session != "" then " · " + $session else "" end)
        + (if $branch != "" then " | 🌿 " + $branch else "" end)
        + (if .pr.number != null
           then " | PR#" + (.pr.number | tostring)
             + (if (.pr.review_state // "") != "" then " " + .pr.review_state else "" end)
           else "" end)
        + (if .context_window.used_percentage != null
           then " | ctx " + pc(.context_window.used_percentage) + "%"
           else "" end)
        + (if .rate_limits.five_hour.used_percentage != null
           then " | 5h " + pc(.rate_limits.five_hour.used_percentage) + "%"
           else "" end)
        + (if .rate_limits.seven_day.used_percentage != null
           then " | 7d " + pc(.rate_limits.seven_day.used_percentage) + "%"
           else "" end)
      ' <<<"$input"
    '';
  };

  subagentStatusLineScript = pkgs.writeShellApplication {
    name = "claude-subagent-statusline";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      jq -cr '
        .tasks[] |
        (.name // .type // "agent") as $name |
        ((.model // "") | sub("^claude-"; "")) as $model |
        (.status // "unknown") as $status |
        (.cwd // "" | split("/") | last) as $dir |
        (.contextWindowSize // 0) as $capacity |
        (.tokenCount // 0) as $tokens |
        {
          id,
          content: (
            $name
            + (if $model != "" then " [" + $model + "]" else "" end)
            + " · " + $status
            + (if $capacity > 0
               then " · ctx " + (($tokens * 100 / $capacity) | floor | tostring) + "%"
               else "" end)
            + (if $dir != "" then " · " + $dir else "" end)
          )
        }
      '
    '';
  };
in
{
  imports = [
    ./lsp.nix
    ./permissions.nix
  ];

  options.khanelinix.programs.terminal.tools.claude-code = {
    enable = mkEnableOption "Claude Code configuration";
  };

  config = mkIf cfg.enable {
    # Install Claude icon for notifications
    xdg.dataFile."icons/claude.ico".source = claudeIcon;

    home.shellAliases = {
      # --dangerously-skip-permissions / --permission-mode bypassPermissions alone still
      # honor permissions.nix's explicit `ask` list (git push, sudo, curl, etc.) - only an
      # explicit `--settings` override with an empty `ask` array clears it. `deny` still
      # merges across every settings layer regardless, so the rm -rf / circuit breaker
      # in permissions.nix keeps applying even under this alias.
      "claude-unsafe" =
        ''claude --permission-mode bypassPermissions --settings '{"permissions":{"ask":[],"defaultMode":"bypassPermissions"}}' '';
    };

    programs.claude-code = {
      enable = true;
      configDir = "${config.xdg.configHome}/claude";

      enableMcpIntegration = mkIf mcpModuleEnabled true;

      settings = {
        inherit hooks;

        model = "claude-fable-5";
        theme = "dark";
        alwaysThinkingEnabled = true;
        autoMemoryEnabled = !aiTools.claudeCode.okfMemoryEnabled;
        # Usage credits
        # fastMode = true;
        cleanupPeriodDays = 90;
        verbose = true;
        workflowSizeGuideline = "small";
        worktree.baseRef = "head";
        attribution = {
          commit = "";
          pr = "";
          sessionUrl = false;
        };

        statusLine = {
          type = "command";
          command = lib.getExe statusLineScript;
          padding = 0;
          refreshInterval = 5;
        };

        subagentStatusLine = {
          type = "command";
          command = lib.getExe subagentStatusLineScript;
        };

        env = {
          USE_BUILTIN_RIPGREP = "0";
        };
      };

      inherit (aiTools.claudeCode) agents commands;
      inherit (aiTools.claudeCode) skills;
      context = aiTools.claudeCode.contextOverride;
    };
  };
}
