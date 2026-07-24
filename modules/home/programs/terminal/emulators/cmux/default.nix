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
  settings = {
    app = {
      commandPaletteSearchesAllSurfaces = true;
      confirmQuit = "dirty-only";
      minimalMode = true;
      openMarkdownInCmuxViewer = true;
      reorderOnNotification = false;
      sendAnonymousTelemetry = false;
    };
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
in
{
  options.khanelinix.programs.terminal.emulators.cmux.enable =
    lib.mkEnableOption "cmux terminal workspace manager";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isSupported;
        message = "cmux is only supported on aarch64-darwin.";
      }
    ];

    home.packages = lib.optionals isSupported [ pkgs.cmux ];

    xdg.configFile = lib.mkIf isSupported {
      "cmux/cmux.json".source = jsonFormat.generate "cmux.json" settings;
    };
  };
}
