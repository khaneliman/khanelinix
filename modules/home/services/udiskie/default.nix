{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.services.udiskie;
in
{
  options.${namespace}.services.udiskie = {
    enable = mkEnableOption "udiskie";
  };

  config = mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
      tray = "auto";
    };
  };
}
