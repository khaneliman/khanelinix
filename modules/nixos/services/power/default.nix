{
  lib,
  config,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.power;
in
{
  options.khanelinix.services.power = {
    enable = lib.mkEnableOption "power profiles daemon";
  };

  config = mkIf cfg.enable {
    # power-profiles-daemon defaults to "balanced" and persists user's choice
    # Use `powerprofilesctl set performance|balanced|power-saver` to change
    services.power-profiles-daemon.enable = true;
  };
}
