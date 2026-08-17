{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.editors.antigravity-ide;
  fontCfg = config.khanelinix.fonts;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/Antigravity/User/settings.json"
    else
      "${config.xdg.configHome}/Antigravity/User/settings.json";
in
{
  options.khanelinix.programs.graphical.editors.antigravity-ide = {
    enable = lib.mkEnableOption "Antigravity IDE configuration";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      # Antigravity rewrites this VS Code-compatible settings file.
      "${settingsPath}".force = true;
    }
    // lib.mapAttrs' (
      name: source:
      lib.nameValuePair ".gemini/antigravity/skills/${name}" {
        source = lib.mkDefault source;
        recursive = true;
      }
    ) aiTools.antigravityCli.skills;

    programs.antigravity = {
      enable = true;
      mutableExtensionsDir = true;
      package = lib.mkDefault null;

      profiles.default = {
        enableExtensionUpdateCheck = false;
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
