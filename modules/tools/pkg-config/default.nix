{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.pkg-config;
in
{
  options.khanelinix.tools.pkg-config = with types; {
    enable = mkBoolOpt false "Whether or not to enable pkg-config.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pkg-config
    ];
  };
}
