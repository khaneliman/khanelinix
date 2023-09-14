{ lib
, config
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.blender;
in
{
  options.khanelinix.apps.blender = {
    enable = mkBoolOpt false "Whether or not to enable blender.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ blender ];
  };
}
