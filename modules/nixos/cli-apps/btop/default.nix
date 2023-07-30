{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.btop;
in
{
  options.khanelinix.cli-apps.btop = with types; {
    enable = mkBoolOpt false "Whether or not to enable btop.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ btop ];

    khanelinix.home = {
      configFile = with inputs; {
        "btop/".source = dotfiles.outPath + "/dots/shared/home/.config/btop";
      };
    };
  };
}
