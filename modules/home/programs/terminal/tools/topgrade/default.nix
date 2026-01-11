{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.topgrade;

  documentsDir =
    if config.xdg.userDirs.enable then
      config.xdg.userDirs.documents
    else
      "${config.home.homeDirectory}/Documents";
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
            "${documentsDir}/github/*/"
            "${documentsDir}/gitlab/*/"
            "${config.xdg.configHome}/.dotfiles/"
            "${config.xdg.configHome}/nvim/"
          ];
        };
      };
    };
  };
}
