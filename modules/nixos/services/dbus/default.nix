{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.services.dbus;
in
{
  options.khanelinix.services.dbus = {
    enable = mkBoolOpt true "Whether or not to enable dbus service.";
  };

  config = mkIf cfg.enable {
    services.dbus = {
      enable = true;

      packages = with pkgs; [
        dconf
        gcr
      ];

      implementation = "broker";
    };
  };
}
