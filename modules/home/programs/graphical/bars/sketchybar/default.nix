{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.programs.graphical.bars.sketchybar;

  shellAliases = {
    push = # bash
      ''command git push && ${getExe config.programs.sketchybar.finalPackage} --trigger git_push'';
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

      zsh.initContent = # bash
        ''
          brew() {
            command brew "$@" && ${getExe config.programs.sketchybar.finalPackage} --trigger brew_update
          }

          mas() {
            command mas "$@" && ${getExe config.programs.sketchybar.finalPackage} --trigger brew_update
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
    };
  };
}
