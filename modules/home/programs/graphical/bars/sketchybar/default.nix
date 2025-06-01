{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.${namespace}.programs.graphical.bars.sketchybar;

  shellAliases = with pkgs; {
    push = # bash
      ''command git push && ${getExe sketchybar} --trigger git_push'';
    restart-sketchybar = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.sketchybar'';
  };
in
{
  options.${namespace}.programs.graphical.bars.sketchybar = {
    enable = lib.mkEnableOption "sketchybar in the desktop environment";
  };

  config = mkIf cfg.enable {
    home.shellAliases = shellAliases;

    programs = {
      sketchybar = {
        enable = true;
        configType = "lua";

        sbarLuaPackage = pkgs.sbarlua;

        extraPackages = with pkgs; [
          blueutil
          coreutils
          curl
          gh
          gh-notify
          gnugrep
          gnused
          jankyborders
          jq
          pkgs.${namespace}.dynamic-island-helper
          pkgs.${namespace}.sketchyhelper
          wttrbar
          yabai
        ];

        config = {
          source = ./config;
          recursive = true;
        };
      };

      zsh.initContent = # bash
        ''
          brew() {
            command brew "$@" && ${getExe pkgs.sketchybar} --trigger brew_update
          }

          mas() {
            command mas "$@" && ${getExe pkgs.sketchybar} --trigger brew_update
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
    };
  };
}
