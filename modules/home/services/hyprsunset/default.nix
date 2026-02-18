{
  config,
  lib,

  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;

  cfg = config.khanelinix.services.hyprsunset;
in
{
  options.khanelinix.services.hyprsunset = {
    enable = mkEnableOption "Hyprsunset";
  };

  config = mkIf cfg.enable {
    services = {
      hyprsunset = {
        enable = true;
        extraArgs = [ "--identity" ];

        settings = {
          profile = [
            {
              time = "5:30";
              temperature = 6500;
              identity = true;
            }
            {
              time = "20:00";
              temperature = 3500;
            }
          ];
        };
      };
    };

    systemd.user.services.hyprsunset.Unit.ConditionEnvironment =
      lib.mkForce "HYPRLAND_INSTANCE_SIGNATURE";
  };
}
