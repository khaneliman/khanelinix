{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.programs.terminal.emulators.alacritty;
in
{
  options.${namespace}.programs.terminal.emulators.alacritty = with types; {
    enable = mkBoolOpt false "Whether to enable alacritty.";
    font = {
      normal = mkOpt str "MonaspiceNe Nerd Font" "Font to use for alacritty.";
      bold = mkOpt str "MonaspiceXe Nerd Font" "Font to use for alacritty.";
      italic = mkOpt str "MonaspiceRn Nerd Font" "Font to use for alacritty.";
      bold_italic = mkOpt str "MonaspiceKr Nerd Font" "Font to use for alacritty.";
    };
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      package = pkgs.alacritty;

      settings =
        {
          cursor = {
            style = {
              shape = "Block";
              blinking = "Off";
            };
          };

          font = {
            size = 13.0;

            offset = {
              x = 0;
              y = 0;
            };

            glyph_offset = {
              x = 0;
              y = 1;
            };

            normal = {
              family = cfg.font.normal;
            };
            bold = {
              family = cfg.font.bold;
              style = "Bold";
            };
            italic = {
              family = cfg.font.italic;
              style = "italic";
            };
            bold_italic = {
              family = cfg.font.bold_italic;
              style = "bold_italic";
            };
          };

          keyboard = {
            bindings = [
              {
                key = "Q";
                mods = "Command";
                action = "Quit";
              }
              {
                key = "W";
                mods = "Command";
                action = "Quit";
              }
              {
                key = "N";
                mods = "Command";
                action = "CreateNewWindow";
              }
            ];
          };

          mouse = {
            hide_when_typing = true;
          };

          window = {
            dimensions = {
              columns = 0;
              lines = 0;
            };

            padding = {
              x = 10;
              y = 10;
            };

            dynamic_padding = true;
            dynamic_title = true;
            opacity = 0.98;
          };
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux { window.decorations = "None"; }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin { window.decorations = "Buttonless"; };
    };
  };
}
