{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.emulators.limux;
  isSupported = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  jsonFormat = pkgs.formats.json { };
  settings.focus.hover_terminal_focus = true;
  shortcuts = {
    focus_down = "<Ctrl><Alt>j";
    focus_left = "<Ctrl><Alt>h";
    focus_right = "<Ctrl><Alt>l";
    focus_up = "<Ctrl><Alt>k";
    terminal_clear_scrollback = null;
    toggle_sidebar = "<Ctrl><Alt>b";
  };
in
{
  options.khanelinix.programs.terminal.emulators.limux.enable =
    lib.mkEnableOption "Limux terminal workspace manager";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isSupported;
        message = "Limux is only packaged for x86_64-linux.";
      }
    ];

    home.packages = lib.optionals isSupported [ pkgs.khanelinix.limux ];

    xdg.configFile = lib.mkIf isSupported {
      "limux/settings.json".source = jsonFormat.generate "limux-settings.json" settings;
      "limux/shortcuts.json".source = jsonFormat.generate "limux-shortcuts.json" {
        inherit shortcuts;
      };
    };
  };
}
