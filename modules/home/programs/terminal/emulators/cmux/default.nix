{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.emulators.cmux;
  isSupported = lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.cmux;
  jsonFormat = pkgs.formats.json { };
in
{
  imports = [ ./layouts.nix ];

  options.khanelinix.programs.terminal.emulators.cmux = {
    enable = lib.mkEnableOption "cmux terminal workspace manager";
    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Settings written to `cmux.json`. Definitions merge per top-level key, so
        sibling modules can own their own sections.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isSupported;
        message = "cmux is only supported on aarch64-darwin.";
      }
    ];

    home.packages = lib.optionals isSupported [ pkgs.cmux ];

    khanelinix.programs.terminal.emulators.cmux.settings = {
      "$schema" = "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json";
      schemaVersion = 1;

      app = {
        commandPaletteSearchesAllSurfaces = true;
        confirmQuit = "dirty-only";
        minimalMode = true;
        openMarkdownInCmuxViewer = true;
        reorderOnNotification = false;
        sendAnonymousTelemetry = false;
        # Without this a new workspace falls back to Ghostty's working-directory,
        # which is the home directory for a GUI launch.
        workspaceInheritWorkingDirectory = true;
      };
      # The layout helpers drive the Unix socket; `cmuxOnly` is upstream's
      # default and restricts control to cmux's own terminals.
      automation.socketControlMode = "cmuxOnly";
      browser.defaultSearchEngine = "duckduckgo";
      shortcuts.bindings = {
        focusDown = "cmd+opt+j";
        focusLeft = "cmd+opt+h";
        focusRight = "cmd+opt+l";
        focusUp = "cmd+opt+k";
        nextSidebarTab = "cmd+opt+shift+j";
        prevSidebarTab = "cmd+opt+shift+k";
      };
      sidebar = {
        branchLayout = "inline";
      };
      sidebarAppearance.matchTerminalBackground = true;
      terminal = {
        copyOnSelect = true;
        showScrollBar = false;
      };
    };

    xdg.configFile = lib.mkIf isSupported {
      "cmux/cmux.json".source = jsonFormat.generate "cmux.json" cfg.settings;
    };
  };
}
