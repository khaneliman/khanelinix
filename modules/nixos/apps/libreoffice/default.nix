{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.libreoffice;
in
{
  options.khanelinix.apps.libreoffice = {
    enable = mkBoolOpt false "Whether or not to enable libreoffice.";
  };
  # TODO: remove module
  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ libreoffice ]; };
}
