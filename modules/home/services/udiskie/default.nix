{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.udiskie;
in
{
  options.khanelinix.services.udiskie = {
    enable = mkEnableOption "udiskie";
  };

  config = mkIf cfg.enable {
    services.udiskie = {
      # Udiskie documentation
      # See: https://github.com/coldfix/udiskie/wiki
      enable = true;
      automount = true;
      notify = true;
      tray = "auto";
    };

    systemd.user.services.udiskie.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
  };
}
