{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.system.input;
  karabinerEnabled = osConfig.services.karabiner-elements.enable or false;
in
{
  options.khanelinix.system.input = {
    enable = mkEnableOption "macOS input";
  };

  config = mkIf cfg.enable {
    services.macos-remap-keys = mkIf (!karabinerEnabled) {
      enable = true;
      keyboard = {
        Capslock = "Escape";
      };
    };

    xdg.configFile."karabiner/karabiner.json" = mkIf karabinerEnabled {
      text = builtins.toJSON {
        global = {
          show_in_menu_bar = false;
        };
        profiles = [
          {
            name = "Default profile";
            selected = true;
            virtual_hid_keyboard = {
              keyboard_type_v2 = "ansi";
            };
            complex_modifications.rules = [
              {
                description = "Caps Lock to Escape if tapped, Left Control if held";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "caps_lock";
                      modifiers.optional = [ "any" ];
                    };
                    to = [
                      {
                        key_code = "left_control";
                        lazy = true;
                      }
                    ];
                    to_if_alone = [
                      {
                        key_code = "escape";
                      }
                    ];
                  }
                ];
              }
            ];
          }
        ];
      };
    };
  };
}
