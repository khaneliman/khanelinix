{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.terminal.emulators.alacritty;
  fontCfg = config.khanelinix.fonts;
in
{
  options.khanelinix.programs.terminal.emulators.alacritty = with types; {
    enable = lib.mkEnableOption "alacritty";
    font = {
      normal = mkOpt str fontCfg.monaspace.families.neon "Font to use for alacritty.";
      bold = mkOpt str fontCfg.monaspace.families.xenon "Font to use for alacritty.";
      italic = mkOpt str fontCfg.monaspace.families.radon "Font to use for alacritty.";
      bold_italic = mkOpt str fontCfg.monaspace.families.krypton "Font to use for alacritty.";
    };
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      package = pkgs.alacritty;

      settings = {
        cursor = {
          style = {
            shape = "Block";
            blinking = "Off";
          };
        };

        font = {
          size = lib.mkDefault 13.0;

          offset = {
            x = 0;
            y = 0;
          };

          glyph_offset = {
            x = 0;
            y = 1;
          };

          normal = {
            family = lib.mkDefault cfg.font.normal;
          };
          bold = {
            family = lib.mkDefault cfg.font.bold;
            style = "Bold";
          };
          italic = {
            family = lib.mkDefault cfg.font.italic;
            style = "italic";
          };
          bold_italic = {
            family = lib.mkDefault cfg.font.bold_italic;
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
