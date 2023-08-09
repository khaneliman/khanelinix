{ options
, config
, lib
, inputs
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.oh-my-posh;
in
{
  options.khanelinix.tools.oh-my-posh = with types; {
    enable = mkBoolOpt false "Whether or not to enable oh-my-posh.";
  };

  config = mkIf cfg.enable {
    programs.oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      package = pkgs.oh-my-posh;

      # settings = ;
    };

    xdg.configFile = with inputs; {
      "ohmyposh/".source = dotfiles.outPath + "/dots/shared/home/.config/ohmyposh";
    };
  };
}
