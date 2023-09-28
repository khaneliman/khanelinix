{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.wshowkeys;
in
{
  options.khanelinix.cli-apps.wshowkeys = {
    enable = mkBoolOpt false "Whether or not to enable wshowkeys.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ wshowkeys ];

    khanelinix.user.extraGroups = [ "input" ];
  };
}
