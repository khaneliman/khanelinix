{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.bars.sketchybar;

  sketchybar = lib.getExe (config.programs.sketchybar.finalPackage or pkgs.sketchybar);
  shellAliases = {
    push = /* bash */ "command git push && ${sketchybar} --trigger git_push";
    restart-sketchybar = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar'';
  };
in
{
  options.khanelinix.programs.graphical.bars.sketchybar = {
    enable = lib.mkEnableOption "sketchybar in the desktop environment";
  };

  config = mkIf cfg.enable {
    home.shellAliases = shellAliases;

    programs = {
      sketchybar = {
        enable = true;
        configType = "lua";

        sbarLuaPackage = pkgs.sbarlua;

        extraPackages =
          with pkgs;
          [
            blueutil
            coreutils
            curl
            gh
            gh-notify
            gnugrep
            gnused
            jankyborders
            jq
            pkgs.khanelinix.dynamic-island-helper
            pkgs.khanelinix.sketchyhelper
            wttrbar
          ]
          ++ lib.optionals (osConfig.khanelinix.desktop.wms.yabai.enable or false) [
            osConfig.services.yabai.package
          ]
          ++ lib.optionals config.khanelinix.programs.graphical.wms.aerospace.enable [
            config.programs.aerospace.package
          ];

        config = {
          source = ./config;
          recursive = true;
        };
      };

      zsh.initContent = /* bash */ ''
        brew() {
          command brew "$@" && ${sketchybar} --trigger brew_update
        }

        mas() {
          command mas "$@" && ${sketchybar} --trigger brew_update
        }
      '';
    };

    xdg.configFile = {
      "dynamic-island-sketchybar" = {
        source = lib.cleanSourceWith { src = lib.cleanSource ./dynamic-island-sketchybar/.; };

        recursive = true;
      };

      "sketchybar/icon_map.lua".source =
        "${pkgs.sketchybar-app-font}/lib/sketchybar-app-font/icon_map.lua";

      "sketchybar/wm_config.lua".text = ''
        -- Window manager configuration for sketchybar
        return {
          use_aerospace = ${
            if (config.khanelinix.programs.graphical.wms.aerospace.enable or false) then "true" else "false"
          },
          use_yabai = ${
            if (osConfig.khanelinix.desktop.wms.yabai.enable or false) then "true" else "false"
          },
        }
      '';

      "sketchybar/colors.lua".text = lib.mkDefault ''
        #!/usr/bin/env lua

        local colors = {
          base = 0xff24273a,
          mantle = 0xff1e2030,
          crust = 0xff181926,
          text = 0xffcad3f5,
          subtext0 = 0xffb8c0e0,
          subtext1 = 0xffa5adcb,
          surface0 = 0xff363a4f,
          surface1 = 0xff494d64,
          surface2 = 0xff5b6078,
          overlay0 = 0xff6e738d,
          overlay1 = 0xff8087a2,
          overlay2 = 0xff939ab7,
          blue = 0xff8aadf4,
          lavender = 0xffb7bdf8,
          sapphire = 0xff7dc4e4,
          sky = 0xff91d7e3,
          teal = 0xff8bd5ca,
          green = 0xffa6da95,
          yellow = 0xffeed49f,
          peach = 0xfff5a97f,
          maroon = 0xffee99a0,
          red = 0xffed8796,
          mauve = 0xffc6a0f6,
          pink = 0xfff5bde6,
          flamingo = 0xfff0c6c6,
          rosewater = 0xfff4dbd6,
        }

        colors.random_cat_color = {
          colors.blue,
          colors.lavender,
          colors.sapphire,
          colors.sky,
          colors.teal,
          colors.green,
          colors.yellow,
          colors.peach,
          colors.maroon,
          colors.red,
          colors.mauve,
          colors.pink,
          colors.flamingo,
          colors.rosewater,
        }

        colors.getRandomCatColor = function()
          return colors.random_cat_color[math.random(1, #colors.random_cat_color)]
        end

        return colors
      '';
    };

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      weather_config = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
