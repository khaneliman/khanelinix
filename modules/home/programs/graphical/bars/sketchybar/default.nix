{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.bars.sketchybar;

  shellAliases = with pkgs; {
    push = # bash
      ''command git push && ${getExe sketchybar} --trigger git_push'';
  };
in
{
  options.${namespace}.programs.graphical.bars.sketchybar = {
    enable = mkBoolOpt false "Whether to enable sketchybar in the desktop environment.";
  };

  config = mkIf cfg.enable {
    home.shellAliases = shellAliases;

    programs.zsh.initExtra = # bash
      ''
        brew() {
          command brew "$@" && ${getExe pkgs.sketchybar} --trigger brew_update
        }

        mas() {
          command mas "$@" && ${getExe pkgs.sketchybar} --trigger brew_update
        }
      '';

    xdg.configFile = {
      "sketchybar" = {
        source = lib.cleanSourceWith { src = lib.cleanSource ./config/.; };

        recursive = true;
      };

      "sketchybar/sketchybarrc" = {
        executable = true;
        text = # Lua
          ''
            #!/usr/bin/env lua

            -- Add the sketchybar module to the package cpath (the module could be
            -- installed into the default search path then this would not be needed)
            package.cpath = package.cpath .. ";${pkgs.khanelinix.sbarlua}/lib/lua/5.4/sketchybar.so"

            Sbar = require("sketchybar")

            Sbar.exec("killall sketchyhelper || sketchyhelper git.felix.sketchyhelper >/dev/null 2>&1 &")

            Sbar.begin_config()
            require("init")
            Sbar.hotload(true)
            Sbar.end_config()

            Sbar.event_loop()
          '';
      };

      "dynamic-island-sketchybar" = {
        source = lib.cleanSourceWith { src = lib.cleanSource ./dynamic-island-sketchybar/.; };

        recursive = true;
      };
    };
  };
}
