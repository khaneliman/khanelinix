{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.bars.sketchybar;

  shellAliases = with pkgs; {
    push = # bash
      ''command git push && ${getExe sketchybar} --trigger git_push'';
  };
in
{
  options.khanelinix.programs.graphical.bars.sketchybar = {
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

      "dynamic-island-sketchybar" = {
        source = lib.cleanSourceWith { src = lib.cleanSource ./dynamic-island-sketchybar/.; };

        recursive = true;
      };
    };
  };
}
