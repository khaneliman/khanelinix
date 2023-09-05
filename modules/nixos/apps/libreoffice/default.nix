{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.libreoffice;
in
{
  options.khanelinix.apps.libreoffice = with types; {
    enable = mkBoolOpt false "Whether or not to enable libreoffice.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ libreoffice ]; };
}
