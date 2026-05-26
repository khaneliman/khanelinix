{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.services.seatd;
in
{
  options.khanelinix.services.seatd = {
    enable = mkEnableOption "seatd";
  };

  config = mkIf cfg.enable {
    services = {
      seatd = {
        enable = true;
        # NOTE: does it matter?
        user = config.khanelinix.user.name;
      };
    };

    # FIXME: https://github.com/NixOS/nixpkgs/pull/521530
    systemd.services.seatd.serviceConfig = {
      Type = lib.mkForce "simple";
      NotifyAccess = lib.mkForce "none";
      ExecStart = lib.mkForce "${pkgs.seatd.bin}/bin/seatd -n 1 -u ${config.services.seatd.user} -g ${config.services.seatd.group} -l ${config.services.seatd.logLevel}";
    };
  };
}
