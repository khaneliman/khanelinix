{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.theme.catppuccin;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix = {
      programs.graphical.browsers.firefox.extensions.settings = {
        "FirefoxColor@mozilla.com" =
          lib.mkIf
            (builtins.elem pkgs.firefox-addons.firefox-color config.khanelinix.programs.graphical.browsers.firefox.extensions.packages)
            {
              force = true;
              settings = {
                "firstRunDone" = true;
                "images" = [ ];
                "theme" = {
                  "colors" = {
                    "toolbar" = {
                      "r" = 36;
                      "g" = 39;
                      "b" = 58;
                    };
                    "toolbar_text" = {
                      "r" = 202;
                      "g" = 211;
                      "b" = 245;
                    };
                    "frame" = {
                      "r" = 24;
                      "g" = 25;
                      "b" = 38;
                    };
                    "tab_background_text" = {
                      "r" = 202;
                      "g" = 211;
                      "b" = 245;
                    };
                    "toolbar_field" = {
                      "r" = 30;
                      "g" = 32;
                      "b" = 48;
                    };
                    "toolbar_field_text" = {
                      "r" = 202;
                      "g" = 211;
                      "b" = 245;
                    };
                    "tab_line" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "popup" = {
                      "r" = 36;
                      "g" = 39;
                      "b" = 58;
                    };
                    "popup_text" = {
                      "r" = 202;
                      "g" = 211;
                      "b" = 245;
                    };
                    "button_background_active" = {
                      "r" = 110;
                      "g" = 115;
                      "b" = 141;
                    };
                    "frame_inactive" = {
                      "r" = 24;
                      "g" = 25;
                      "b" = 38;
                    };
                    "icons_attention" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "icons" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "ntp_background" = {
                      "r" = 24;
                      "g" = 25;
                      "b" = 38;
                    };
                    "ntp_text" = {
                      "r" = 202;
                      "g" = 211;
                      "b" = 245;
                    };
                    "popup_border" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "popup_highlight_text" = {
                      "r" = 202;
                      "g" = 211;
                      "b" = 245;
                    };
                    "popup_highlight" = {
                      "r" = 110;
                      "g" = 115;
                      "b" = 141;
                    };
                    "sidebar_border" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "sidebar_highlight_text" = {
                      "r" = 24;
                      "g" = 25;
                      "b" = 38;
                    };
                    "sidebar_highlight" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "sidebar_text" = {
                      "r" = 202;
                      "g" = 211;
                      "b" = 245;
                    };
                    "sidebar" = {
                      "r" = 36;
                      "g" = 39;
                      "b" = 58;
                    };
                    "tab_background_separator" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "tab_loading" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "tab_selected" = {
                      "r" = 36;
                      "g" = 39;
                      "b" = 58;
                    };
                    "tab_text" = {
                      "r" = 202;
                      "g" = 211;
                      "b" = 245;
                    };
                    "toolbar_bottom_separator" = {
                      "r" = 36;
                      "g" = 39;
                      "b" = 58;
                    };
                    "toolbar_field_border_focus" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "toolbar_field_border" = {
                      "r" = 36;
                      "g" = 39;
                      "b" = 58;
                    };
                    "toolbar_field_focus" = {
                      "r" = 36;
                      "g" = 39;
                      "b" = 58;
                    };
                    "toolbar_field_highlight_text" = {
                      "r" = 36;
                      "g" = 39;
                      "b" = 58;
                    };
                    "toolbar_field_highlight" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "toolbar_field_separator" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                    "toolbar_vertical_separator" = {
                      "r" = 138;
                      "g" = 173;
                      "b" = 244;
                    };
                  };
                  "images" = {
                    "additional_backgrounds" = [ "./bg-000.svg" ];
                    "custom_backgrounds" = [ ];
                  };
                  "title" = "Catppuccin macchiato blue";
                };
              };
            };
      };
    };
  };
}
