{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.emulators.limux;
  isSupported = lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.khanelinix.limux;
  jsonFormat = pkgs.formats.json { };
in
{
  imports = [ ./layouts.nix ];

  options.khanelinix.programs.terminal.emulators.limux = {
    enable = lib.mkEnableOption "Limux terminal workspace manager";

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Settings written to `settings.json`. Definitions merge per top-level
        key, so sibling modules can own their own sections. Limux ignores keys
        it does not recognize.
      '';
    };

    shortcuts = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Bindings written as the `shortcuts` object of `shortcuts.json`. Keys are
        Limux's built-in action ids, values are GTK accelerator strings, and
        `null` unbinds an action.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isSupported;
        message = "Limux is only packaged for x86_64-linux.";
      }
    ];

    home.packages = lib.optionals isSupported [ pkgs.khanelinix.limux ];

    khanelinix.programs.terminal.emulators.limux = {
      # Per-leaf `mkDefault` so a sibling can override one binding without
      # restating the rest: plain assignment makes an override a conflicting
      # definition, and wrapping the attrset lets one key suppress the others.
      settings.focus.hover_terminal_focus = lib.mkDefault true;

      shortcuts = {
        focus_down = lib.mkDefault "<Ctrl><Alt>j";
        focus_left = lib.mkDefault "<Ctrl><Alt>h";
        focus_right = lib.mkDefault "<Ctrl><Alt>l";
        focus_up = lib.mkDefault "<Ctrl><Alt>k";
        terminal_clear_scrollback = lib.mkDefault null;
        toggle_sidebar = lib.mkDefault "<Ctrl><Alt>b";
      };
    };

    xdg.configFile = lib.mkIf isSupported {
      "limux/settings.json".source = jsonFormat.generate "limux-settings.json" cfg.settings;
      # The option holds the inner object so definitions merge per action rather
      # than per file.
      "limux/shortcuts.json".source = jsonFormat.generate "limux-shortcuts.json" {
        inherit (cfg) shortcuts;
      };
    };
  };
}
