{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.libreoffice;
in
{
  options.khanelinix.apps.libreoffice = with types; {
    enable = mkBoolOpt false "Whether or not to enable libreoffice.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ libreoffice ]; };
}
