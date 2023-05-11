{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.meson;
in
{
  options.khanelinix.tools.meson = with types; {
    enable = mkBoolOpt false "Whether or not to enable meson.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      meson
    ];
  };
}
