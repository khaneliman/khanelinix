{ options
, config
, lib
, pkgs
, inputs
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
    environment.systemPackages = with pkgs; [
      oh-my-posh
    ];

    khanelinix.home = {
      configFile = with inputs; {
        "ohmyposh/".source = dotfiles.outPath + "/dots/shared/home/.config/ohmyposh";
      };
    };
  };
}
