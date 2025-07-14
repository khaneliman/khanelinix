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

        transitions = {
          sunrise = {
            calendar = "*-*-* 05:30:00";
            requests = [
              [ "temperature 6500" ]
              [ "identity" ]
            ];
          };

          sunset = {
            calendar = "*-*-* 20:00:00";
            requests = [ [ "temperature 3500" ] ];
          };
        };
      };
    };
  };
}
