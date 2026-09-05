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
    mkOption
    types
    ;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.khanelinix.programs.graphical.apps.claude-desktop;
  configDirectory =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/Claude"
    else
      "${config.xdg.configHome}/Claude";

  applicationSettingsFile = pkgs.writeText "claude-desktop-application-settings.json" (
    builtins.toJSON {
      inherit (cfg) locale;
      userThemeMode = cfg.themeMode;
    }
  );

  desktopSettingsFile = pkgs.writeText "claude-desktop-settings.json" (
    builtins.toJSON {
      preferences = {
        inherit (cfg) ccdScheduledTasksEnabled;
        coworkHipaaRestricted = cfg.hipaaRestricted;
        inherit (cfg) coworkScheduledTasksEnabled;
        coworkWebSearchEnabled = cfg.webSearchEnabled;
        dispatchCodeTasksPermissionMode = cfg.codeTasksPermissionMode;
        inherit (cfg) sidebarMode;
      };
    }
  );

  applySettings = pkgs.writeShellApplication {
    name = "claude-desktop-apply-settings";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      config_dir=${lib.escapeShellArg configDirectory}
      mkdir -p "$config_dir"

      merge_settings() {
        config_file="$1"
        managed_file="$2"
        temporary_file="$(mktemp "$config_dir/claude-settings.XXXXXX")"

        if [ -f "$config_file" ]; then
          jq --slurpfile managed "$managed_file" \
            'if type == "object" then . * $managed[0] else $managed[0] end' \
            "$config_file" >"$temporary_file"
        else
          cp "$managed_file" "$temporary_file"
        fi

        mv "$temporary_file" "$config_file"
      }

      merge_settings "$config_dir/config.json" ${applicationSettingsFile}
      merge_settings "$config_dir/claude_desktop_config.json" ${desktopSettingsFile}
    '';
  };
in
{
  options.khanelinix.programs.graphical.apps.claude-desktop = {
    enable = mkEnableOption "Claude Desktop integration";
    locale = mkOption {
      type = types.str;
      default = "en-US";
      description = "Claude Desktop locale.";
    };
    themeMode = mkOption {
      type = types.enum [
        "system"
        "light"
        "dark"
      ];
      default = "system";
      description = "Claude Desktop appearance mode.";
    };
    sidebarMode = mkOption {
      type = types.enum [
        "epitaxy"
        "legacy"
      ];
      default = "epitaxy";
      description = "Claude Desktop sidebar implementation.";
    };
    ccdScheduledTasksEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "Whether Claude Code scheduled tasks are enabled in Claude Desktop.";
    };
    coworkScheduledTasksEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "Whether Claude Desktop Cowork scheduled tasks are enabled.";
    };
    webSearchEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "Whether Claude Desktop Cowork can search the web.";
    };
    hipaaRestricted = mkOption {
      type = types.bool;
      default = false;
      description = "Whether Claude Desktop uses Cowork HIPAA restrictions.";
    };
    codeTasksPermissionMode = mkOption {
      type = types.enum [
        "default"
        "acceptEdits"
        "bypassPermissions"
      ];
      default = "default";
      description = ''
        Permission mode for Claude Code tasks dispatched from the desktop app.
        Left unmanaged, the app persisted bypassPermissions, which sidesteps
        the permission catalog every other tool follows.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.optionals (!isDarwin) [ pkgs.claude-desktop ];

    # Preserve account tokens, workspace state, and application migrations.
    # Claude Desktop stores those values beside the declarative preferences.
    home.activation.claudeDesktopSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe applySettings}
    '';
  };
}
