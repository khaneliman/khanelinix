{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  cfg = config.khanelinix.system.input;
  karabinerEnabled = osConfig.services.karabiner-elements.enable or false;

  anyModifiers = {
    optional = [ "any" ];
  };

  hyperLayerCondition = {
    type = "variable_if";
    name = "hyper_layer";
    value = 1;
  };

  builtInKeyboardCondition = {
    type = "device_if";
    identifiers = [
      {
        is_built_in_keyboard = true;
      }
    ];
  };

  mkKey = keyCode: {
    key_code = keyCode;
  };

  mkModifiedKey = keyCode: modifiers: {
    key_code = keyCode;
    inherit modifiers;
  };

  mkHyperLayerManipulator = keyCode: to: {
    type = "basic";
    from = {
      key_code = keyCode;
      modifiers = anyModifiers;
    };
    conditions = [ hyperLayerCondition ];
    inherit to;
  };

  hyperModifiers = [
    "left_command"
    "left_control"
    "left_option"
  ];

  karabinerConfig = {
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
            description = "Caps Lock to Escape if tapped, Left Control if held on the built-in keyboard";
            manipulators = [
              {
                type = "basic";
                from = {
                  key_code = "caps_lock";
                  modifiers = anyModifiers;
                };
                conditions = [ builtInKeyboardCondition ];
                to = [
                  {
                    key_code = "left_control";
                    lazy = true;
                  }
                ];
                to_if_alone = [
                  (mkKey "escape")
                ];
                parameters = {
                  "basic.to_if_alone_timeout_milliseconds" = 200;
                  "basic.to_if_held_down_threshold_milliseconds" = 150;
                };
              }
            ];
          }
          {
            description = "Right Command to Hyper";
            manipulators = [
              {
                type = "basic";
                from = {
                  key_code = "right_command";
                  modifiers = anyModifiers;
                };
                to = [
                  {
                    set_variable = {
                      name = "hyper_layer";
                      value = 1;
                    };
                  }
                  {
                    key_code = "left_shift";
                    modifiers = hyperModifiers;
                    lazy = true;
                  }
                ];
                to_after_key_up = [
                  {
                    set_variable = {
                      name = "hyper_layer";
                      value = 0;
                    };
                  }
                ];
                to_if_alone = [
                  (mkKey "right_command")
                ];
                parameters = {
                  "basic.to_if_alone_timeout_milliseconds" = 250;
                };
              }
            ];
          }
          {
            description = "Hyper navigation and editing layer";
            manipulators = map (mapping: mkHyperLayerManipulator mapping.key mapping.to) [
              {
                key = "h";
                to = [ (mkKey "left_arrow") ];
              }
              {
                key = "j";
                to = [ (mkKey "down_arrow") ];
              }
              {
                key = "k";
                to = [ (mkKey "up_arrow") ];
              }
              {
                key = "l";
                to = [ (mkKey "right_arrow") ];
              }
              {
                key = "b";
                to = [ (mkModifiedKey "left_arrow" [ "left_option" ]) ];
              }
              {
                key = "f";
                to = [ (mkModifiedKey "right_arrow" [ "left_option" ]) ];
              }
              {
                key = "a";
                to = [ (mkModifiedKey "left_arrow" [ "left_command" ]) ];
              }
              {
                key = "e";
                to = [ (mkModifiedKey "right_arrow" [ "left_command" ]) ];
              }
              {
                key = "u";
                to = [ (mkKey "page_up") ];
              }
              {
                key = "i";
                to = [ (mkKey "page_down") ];
              }
              {
                key = "d";
                to = [ (mkKey "delete_forward") ];
              }
            ];
          }
        ];
      }
    ];
  };
in
{
  config = lib.mkIf (cfg.enable && karabinerEnabled) {
    xdg.configFile."karabiner/karabiner.json".text = builtins.toJSON karabinerConfig;
  };
}
