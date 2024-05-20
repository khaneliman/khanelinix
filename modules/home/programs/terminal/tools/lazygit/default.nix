{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.lazygit;
in
{
  options.khanelinix.programs.terminal.tools.lazygit = {
    enable = mkBoolOpt false "Whether or not to enable lazygit.";
  };

  config = mkIf cfg.enable {
    programs.lazygit = {
      enable = true;

      settings = {
        git = {
          overrideGpg = true;
        };
      };
    };

    home.shellAliases = {
      lg = "lazygit";
    };
  };
}
