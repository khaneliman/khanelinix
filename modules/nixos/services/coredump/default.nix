{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.services.coredump;
in
{
  options.khanelinix.services.coredump = {
    enable = mkEnableOption "systemd-coredump storage limits";
  };

  config = mkIf cfg.enable {
    # systemd-coredump otherwise keeps up to 10% of /var; a crash-looping
    # program can pin gigabytes of identical dumps.
    systemd.coredump.settings.Coredump = {
      MaxUse = "1G";
      KeepFree = "2G";
    };
  };
}
