{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.desktop.addons.alacritty;

  macchiato = {
    primary = {
      # Default colors
      background = "#24273A"; # base
      foreground = "#CAD3F5"; # text

      # Bright and dim foreground colors
      dim_foreground = "#CAD3F5"; # text
      bright_foreground = "#CAD3F5"; # text }
    };

    # Cursor colors
    cursor = {
      text = "#24273A"; # base
      cursor = "#F4DBD6"; # rosewater
    };

    vi_mode_cursor = {
      text = "#24273A"; # base
      cursor = "#B7BDF8"; # lavender
    };

    # Search colors
    search = {
      matches = {
        foreground = "#24273A"; # base
        background = "#A5ADCB"; # subtext0
      };

      focused_match = {
        foreground = "#24273A"; # base
        background = "#A6DA95"; # green
      };

      footer_bar = {
        foreground = "#24273A"; # base
        background = "#A5ADCB"; # subtext0
      };
    };

    # Keyboard regex hints
    hints = {
      start = {
        foreground = "#24273A"; # base
        background = "#EED49F"; # yellow
      };

      end = {
        foreground = "#24273A"; # base
        background = "#A5ADCB"; # subtext0
      };
    };

    # Selection colors
    selection = {
      text = "#24273A"; # base
      background = "#F4DBD6"; # rosewater
    };

    # Normal colors
    normal = {
      black = "#494D64"; # surface1
      red = "#ED8796"; # red
      green = "#A6DA95"; # green
      yellow = "#EED49F"; # yellow
      blue = "#8AADF4"; # blue
      magenta = "#F5BDE6"; # pink
      cyan = "#8BD5CA"; # teal
      white = "#B8C0E0"; # subtext1
    };

    # Bright colors
    bright = {
      black = "#5B6078"; # surface2
      red = "#ED8796"; # red
      green = "#A6DA95"; # green
      yellow = "#EED49F"; # yellow
      blue = "#8AADF4"; # blue
      magenta = "#F5BDE6"; # pink
      cyan = "#8BD5CA"; # teal
      white = "#A5ADCB"; # subtext0
    };

    # Dim colors
    dim = {
      black = "#494D64"; # surface1
      red = "#ED8796"; # red
      green = "#A6DA95"; # green
      yellow = "#EED49F"; # yellow
      blue = "#8AADF4"; # blue
      magenta = "#F5BDE6"; # pink
      cyan = "#8BD5CA"; # teal
      white = "#B8C0E0"; # subtext1
    };

    indexed_colors = [
      {
        index = 16;
        color = "#F5A97F";
      }
      {
        index = 17;
        color = "#F4DBD6";
      }
    ];
  };
in
{
  options.khanelinix.desktop.addons.alacritty = with types; {
    enable = mkBoolOpt false "Whether to enable alacritty.";
    theme = mkOpt attr macchiato "Theme to use for alacritty.";
    font = mkOpt str "Liga SFMono Nerd Font" "Font to use for alacritty.";
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      package = pkgs.alacritty;

      settings =
        {
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

          font = {
            size = 12.0;

            offset = {
              x = 0;
              y = 0;
            };

            glyph_offset = {
              x = 0;
              y = 1;
            };

            normal = {
              family = cfg.font;
            };
            bold = {
              family = cfg.font;
              style = "Bold";
            };
            italic = {
              family = cfg.font;
              style = "italic";
            };
            bold_italic = {
              family = cfg.font;
              style = "bold_italic";
            };
          };

          colors = cfg.theme;

          cursor = {
            style = {
              shape = "Block";
              blinking = "Off";
            };
          };

          mouse = {
            hide_when_typing = true;
          };

          keybindings = with lib; [
            {
              key = Q;
              mods = Command;
              action = Quit;
            }
            {
              key = W;
              mods = Command;
              action = Quit;
            }
            {
              key = N;
              mods = Command;
              action = CreateNewWindow;
            }
          ];
        }
        // lib.optionalAttrs
          pkgs.stdenv.isLinux
          { window.decorations = "None"; }
        // lib.optionalAttrs
          pkgs.stdenv.isDarwin
          { window.decorations = "Buttonless"; };
    };
  };
}
