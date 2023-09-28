{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.colorls;
in
{
  options.khanelinix.tools.colorls = {
    enable = mkBoolOpt false "Whether or not to enable colorls.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      colorls
    ];

    khanelinix.home.extraOptions.home.shellAliases = {
      lc = "colorls --sd";
      lcg = "lc --gs";
      lcl = "lc -1";
      lclg = "lc -1 --gs";
      lcu = "colorls -U";
      lclu = "colorls -U -1";
    };
  };
}
