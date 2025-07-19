{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.topgrade;
in
{
  options.khanelinix.programs.terminal.tools.topgrade = {
    enable = lib.mkEnableOption "topgrade";
  };

  config = mkIf cfg.enable {
    programs.topgrade = {
      enable = true;

      settings = {
        misc = {
          no_retry = true;
          display_time = true;
          skip_notify = true;
        };
        git = {
          repos = [
            "~/Documents/github/*/"
            "~/Documents/gitlab/*/"
            "~/.config/.dotfiles/"
            "~/.config/nvim/"
          ];
        };
      };
    };
  };
}
