{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.cli-apps.wshowkeys;
in
{
  options.khanelinix.cli-apps.wshowkeys = with types; {
    enable = mkBoolOpt false "Whether or not to enable wshowkeys.";
  };

  config = mkIf cfg.enable {
    khanelinix.user.extraGroups = [ "input" ];
    environment.systemPackages = with pkgs; [ wshowkeys ];
  };
}
