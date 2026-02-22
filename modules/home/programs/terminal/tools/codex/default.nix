{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.tools.codex;

  codexNotify = pkgs.writeShellApplication {
    name = "codex-notify";
    runtimeInputs = [
      pkgs.jq
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libnotify ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.terminal-notifier ];
    text = ''
      payload="$1"
      eventType="$(printf '%s' "$payload" | jq -r '.type // ""')"
      [ "$eventType" = "agent-turn-complete" ] || exit 0

      message="$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // "Turn complete"')"
      summary="$(printf '%s' "$message" | cut -c1-180)"

      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        ${lib.getExe pkgs.terminal-notifier} -title "Codex" -message "$summary" -group "codex-turn" >/dev/null 2>&1
      ''}
      ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        ${lib.getExe pkgs.libnotify}/bin/notify-send "Codex" "$summary" >/dev/null 2>&1
      ''}
    '';
  };
in
{
  options.khanelinix.programs.terminal.tools.codex = {
    enable = mkEnableOption "Codex configuration";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;
      enableMcpIntegration = true;

      settings = {
        features = {
          shell_snapshot = true;
          multi_agent = true;
          apps = true;
        };

        history = {
          persistence = "save-all";
          max_bytes = 104857600;
        };

        model = "gpt-5.3-codex";
        model_reasoning_effort = "high";

        notify = [ (lib.getExe codexNotify) ];
        personality = "pragmatic";

        project_root_markers = [
          ".git"
          ".jj"
          ".hg"
          ".sl"
        ];

        sandbox_mode = "workspace-write";

        profiles = {
          # Deep, deliberate analysis mode.
          deep = {
            model_reasoning_effort = "xhigh";
            model_verbosity = "high";
            approval_policy = "on-request";
          };

          # Faster implementation loop for coding tasks.
          quick = {
            model_reasoning_effort = "medium";
            model_reasoning_summary = "none";
            model_verbosity = "low";
            approval_policy = "on-request";
          };

          # Force local-only behavior when you do not want network access.
          offline = {
            sandbox_workspace_write.network_access = false;
          };

          # Token-enabled profile for package updates and other API-heavy workflows.
          unsafe = {
            approval_policy = "on-request";
            shell_environment_policy.ignore_default_excludes = true;
          };
        };

        projects =
          let
            khanelinixPath = "${config.home.homeDirectory}/khanelinix";
            githubPath =
              let
                documentsPath =
                  if config.xdg.userDirs.enable then
                    config.xdg.userDirs.documents
                  else
                    config.home.homeDirectory + lib.optionalString pkgs.stdenv.hostPlatform.isLinux "/Documents";
              in
              "${documentsPath}/github";
            khanelivimPath = "${githubPath}/khanelivim";
          in
          {
            "${khanelinixPath}" = {
              trust_level = "trusted";
            };
            "${khanelivimPath}" = {
              trust_level = "trusted";
            };
          };
      };

      custom-instructions = builtins.readFile (lib.getFile "modules/common/ai-tools/base.md");
      skills = lib.getFile "modules/common/ai-tools/skills";
    };
  };
}
