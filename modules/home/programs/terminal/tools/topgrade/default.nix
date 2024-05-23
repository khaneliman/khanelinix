{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.topgrade;
in
{
  options.${namespace}.programs.terminal.tools.topgrade = {
    enable = mkBoolOpt false "Whether or not to enable topgrade.";
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
