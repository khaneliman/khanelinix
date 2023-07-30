{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.glxinfo;
in
{
  options.khanelinix.tools.glxinfo = with types; {
    enable = mkBoolOpt false "Whether or not to enable glxinfo.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      glxinfo
    ];
  };
}
