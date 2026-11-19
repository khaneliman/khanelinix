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
        # Leave Ctrl+Alt workspace and VoxType chords to the compositor.
        activate_workspace_1 = lib.mkDefault "<Ctrl><Shift>1";
        activate_workspace_2 = lib.mkDefault "<Ctrl><Shift>2";
        activate_workspace_3 = lib.mkDefault "<Ctrl><Shift>3";
        activate_workspace_4 = lib.mkDefault "<Ctrl><Shift>4";
        activate_workspace_5 = lib.mkDefault "<Ctrl><Shift>5";
        activate_workspace_6 = lib.mkDefault "<Ctrl><Shift>6";
        activate_workspace_7 = lib.mkDefault "<Ctrl><Shift>7";
        activate_workspace_8 = lib.mkDefault "<Ctrl><Shift>8";
        activate_last_workspace = lib.mkDefault "<Ctrl><Shift>9";
        cycle_tab_prev = lib.mkDefault "<Alt><Shift>comma";
        cycle_tab_next = lib.mkDefault "<Alt><Shift>period";
        focus_down = lib.mkDefault "<Alt><Shift>j";
        focus_left = lib.mkDefault "<Alt><Shift>h";
        focus_right = lib.mkDefault "<Alt><Shift>l";
        focus_up = lib.mkDefault "<Alt><Shift>k";
        split_right = lib.mkDefault "<Ctrl><Alt>v";
        split_down = lib.mkDefault "<Ctrl><Alt><Shift>v";
        surface_find = lib.mkDefault "<Ctrl><Shift>f";
        terminal_clear_scrollback = lib.mkDefault null;
        terminal_reset_font_size = lib.mkDefault "<Ctrl><Shift>0";
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
