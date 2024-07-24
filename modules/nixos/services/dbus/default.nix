{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.dbus;
in
{
  options.${namespace}.services.dbus = {
    enable = mkBoolOpt true "Whether or not to enable dbus service.";
  };

  config = mkIf cfg.enable {
    services.dbus = {
      enable = true;

      packages = with pkgs; [
        dconf
        gcr
        udisks2
      ];

      implementation = "broker";
    };
  };
}
