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

  cfg = config.khanelinix.programs.graphical.editors.antigravity;
  fontCfg = config.khanelinix.fonts;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };

  globalSettingsFile = pkgs.writeText "antigravity-global-settings.json" (
    builtins.toJSON {
      userSettings = {
        autoExecutionPolicy = "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER";
        customThemeSeedsDark = {
          background = "#1A1B26";
          foregroundOverride = "#A9B1D6";
          primary = "#7AA2F7";
        };
        customThemeSeedsLight = {
          background = "#EAECF0";
          foregroundOverride = "#4C4F69";
          primary = "#8839EF";
        };
        enableTerminalSandbox = false;
        globalPermissionGrants.allow = [
          "mcp(git/git_status)"
          "mcp(git/git_diff)"
          "mcp(git/git_diff_unstaged)"
          "mcp(git/git_add)"
          "mcp(git/git_log)"
        ];
        nonWorkspaceFileAccessPolicy = "AGENT_SETTING_POLICY_ALLOW";
        queuedMessageDeliveryStrategy = "MESSAGE_DELIVERY_STRATEGY_NEXT_INVOCATION";
      };
    }
  );
in
{
  options.khanelinix.programs.graphical.editors.antigravity = {
    enable = mkEnableOption "Antigravity IDE configuration";
  };

  config = mkIf cfg.enable {
    home = {
      activation.antigravityGlobalSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config_file="${config.home.homeDirectory}/.gemini/config/config.json"
        declared_file=${globalSettingsFile}

        run mkdir -p "$(dirname "$config_file")"
        temporary_file="$(mktemp "$config_file.tmp.XXXXXX")"

        if [ -f "$config_file" ]; then
          ${lib.getExe pkgs.jq} --slurpfile declared "$declared_file" \
            'if type == "object" then . * $declared[0] else $declared[0] end' \
            "$config_file" > "$temporary_file"
        else
          run cp "$declared_file" "$temporary_file"
        fi

        run mv "$temporary_file" "$config_file"
      '';

      file = {
        ".gemini/config/plugins/okf-memory".source = lib.mkDefault aiTools.antigravityCli.okfMemoryPlugin;
        ".gemini/config/plugins/technical-writing".source =
          lib.mkDefault aiTools.antigravityCli.technicalWritingPlugin;

        # Antigravity rewrites this VS Code-compatible settings file.
        "${config.home.homeDirectory}/Library/Application Support/Antigravity/User/settings.json".force =
          true;
      }
      // lib.mapAttrs' (
        name: source:
        lib.nameValuePair ".gemini/config/skills/${name}" {
          source = lib.mkDefault source;
          recursive = true;
        }
      ) aiTools.antigravityCli.skills;
    };

    programs.antigravity = {
      enable = true;
      mutableExtensionsDir = true;
      package = lib.mkDefault null;

      profiles.default = {
        enableExtensionUpdateCheck = false;
        enableMcpIntegration = mkIf mcpModuleEnabled true;
        enableUpdateCheck = false;

        extensions = with pkgs.vscode-extensions; [
          enkia.tokyo-night
          vscode-icons-team.vscode-icons
        ];

        userSettings = {
          "breadcrumbs.enabled" = true;
          "chat.editor.fontFamily" = fontCfg.monaspace.stacks.editor;
          "editor.bracketPairColorization.enabled" = true;
          "editor.codeLensFontFamily" = fontCfg.monaspace.stacks.ui;
          "editor.fontFamily" = fontCfg.monaspace.stacks.editor;
          "editor.fontLigatures" =
            "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'ss09', 'ss10', 'dlig', 'liga'";
          "editor.fontSize" = 16;
          "editor.formatOnPaste" = true;
          "editor.formatOnSave" = true;
          "editor.guides.bracketPairs" = true;
          "editor.guides.indentation" = true;
          "editor.inlayHints.fontFamily" = "MonaspaceKrypton NF, Monaspace Krypton NF";
          "editor.minimap.enabled" = false;
          "editor.overviewRulerBorder" = false;
          "editor.renderLineHighlight" = "all";
          "editor.smoothScrolling" = true;
          "explorer.confirmDelete" = false;
          "files.trimTrailingWhitespace" = true;
          "git.allowForcePush" = true;
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "git.openRepositoryInParentFolders" = "always";
          "terminal.integrated.cursorBlinking" = true;
          "terminal.integrated.enableBell" = false;
          "terminal.integrated.fontFamily" = fontCfg.monaspace.stacks.terminal;
          "terminal.integrated.gpuAcceleration" = "on";
          "telemetry.telemetryLevel" = "off";
          "window.nativeTabs" = true;
          "window.restoreWindows" = "all";
          "workbench.colorTheme" = "Tokyo Night";
          "workbench.editor.tabCloseButton" = "left";
          "workbench.fontAliasing" = "antialiased";
          "workbench.iconTheme" = "vscode-icons";
          "workbench.list.smoothScrolling" = true;
          "workbench.panel.defaultLocation" = "right";
          "workbench.startupEditor" = "none";
        };
      };
    };
  };
}
