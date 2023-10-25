{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.fzf;
in
{
  options.khanelinix.tools.fzf = {
    enable = mkBoolOpt false "Whether or not to enable fzf.";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      package = pkgs.fzf;

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      tmux = {
        enableShellIntegration = true;
      };
    };
  };
}
