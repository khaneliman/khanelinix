{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.sketchybar;

  shellAliases = with pkgs; {
    push = /* bash */ ''command git push && ${getExe sketchybar} --trigger git_push'';
  };
in
{
  options.khanelinix.desktop.addons.sketchybar = {
    enable =
      mkBoolOpt false "Whether to enable sketchybar in the desktop environment.";
  };

  config = mkIf cfg.enable {
    home.shellAliases = shellAliases;

    programs = {
      sketchybar = {
        enable = true;

        config = {
          bar = {
            blur_radius = 30;
            border_color = "$SURFACE1";
            border_width = 2;
            color = "$BASE";
            corner_radius = 9;
            height = 40;
            margin = 10;
            notch_width = 0;
            padding_left = 18;
            padding_right = 10;
            position = "top";
            shadow = "on";
            sticky = "on";
            topmost = "off";
            y_offset = 10;
          };

          defaults = {
            "icon.color" = "$TEXT";
            "icon.font" = "$NERD_FONT:Bold:16.0";
            "icon.padding_left" = "$PADDINGS";
            "icon.padding_right" = "$PADDINGS";
            "label.color" = "$TEXT";
            "label.font" = "$FONT:Semibold:13.0";
            "label.padding_left" = "$PADDINGS";
            "label.padding_right" = "$PADDINGS";
            "background.corner_radius" = 9;
            "background.height" = 30;
            "background.padding_left" = "$PADDINGS";
            "background.padding_right" = "$PADDINGS";
            "popup.height" = 30;
            "popup.horizontal" = "false";
            "popup.background.border_color" = "$BLUE";
            "popup.background.border_width" = 2;
            "popup.background.color" = "$MANTLE";
            "popup.background.corner_radius" = 11;
            "popup.background.shadow.drawing" = "on";
          };
        };

        sources = [
          ./config/colors.sh
          ./config/icons.sh
          ./config/userconfig.sh
        ];

        plugins = builtins.filter (path: lib.hasSuffix "item.sh" (baseNameOf (toString path))) (lib.snowfall.fs.get-files-recursive ./config/plugins);

        variables = {
          FONT = "SF Pro";
          NERD_FONT = "MonaspiceNe Nerd Font";

          PADDINGS = "3";

          BASE = "0xff24273a";
          MANTLE = "0xff1e2030";
          CRUST = "0xff181926";

          TEXT = "0xffcad3f5";
          SUBTEXT0 = "0xffb8c0e0";
          SUBTEXT1 = "0xffa5adcb";

          SURFACE0 = "0xff363a4f";
          SURFACE1 = "0xff494d64";
          SURFACE2 = "0xff5b6078";

          OVERLAY0 = "0xff6e738d";
          OVERLAY1 = "0xff8087a2";
          OVERLAY2 = "0xff939ab7";

          BLUE = "0xff8aadf4";
          LAVENDER = "0xffb7bdf8";
          SAPPHIRE = "0xff7dc4e4";
          SKY = "0xff91d7e3";
          TEAL = "0xff8bd5ca";
          GREEN = "0xffa6da95";
          YELLOW = "0xffeed49f";
          PEACH = "0xfff5a97f";
          MAROON = "0xffee99a0";
          RED = "0xffed8796";
          MAUVE = "0xffc6a0f6";
          PINK = "0xfff5bde6";
          FLAMINGO = "0xfff0c6c6";
          ROSEWATER = "0xfff4dbd6";

          LOADING = "";
          APPLE = "";
          PREFERENCES = "";
          ACTIVITY = "";
          LOCK = "";
          LOGOUT = "";
          POWER = "";
          REBOOT = "";
          SLEEP = "⏾";
          BELL = "";
          BELL_DOT = "";

          BATTERY = "";
          CPU = "";
          DISK = "󰋊";
          MEMORY = "﬙";
          NETWORK = "";
          NETWORK_DOWN = "";
          NETWORK_UP = "";

          # Git Icons
          GIT_ISSUE = "";
          GIT_DISCUSSION = "";
          GIT_PULL_REQUEST = "";
          GIT_COMMIT = "";
          GIT_INDICATOR = "";

          # Spotify Icons
          SPOTIFY_BACK = "";
          SPOTIFY_PLAY_PAUSE = "";
          SPOTIFY_NEXT = "";
          SPOTIFY_SHUFFLE = "";
          SPOTIFY_REPEAT = "";

          # Yabai Icons
          YABAI_STACK = "";
          YABAI_FULLSCREEN_ZOOM = "";
          YABAI_PARENT_ZOOM = "";
          YABAI_FLOAT = "";
          YABAI_GRID = "";
        };
      };

      zsh.initExtra = /* bash */ ''
        brew() {
          command brew "$@" && ${getExe pkgs.sketchybar} --trigger brew_update
        }

        mas() {
          command mas "$@" && ${getExe pkgs.sketchybar} --trigger brew_update
        }
      '';
    };

    xdg.configFile = {
      # "sketchybar/sketchybarrc".source = getExe pkgs.khanelinix.sketchybarrc;

      "dynamic-island-sketchybar" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource ./dynamic-island-sketchybar/.;
        };

        recursive = true;
      };
    };
  };
}
