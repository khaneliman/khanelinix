{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;

  cfg = config.${namespace}.services.hyprsunset;
in
{
  options.${namespace}.services.hyprsunset = {
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
            calendar = "*-*-* 14:55:00";
            requests = [ [ "temperature 3500" ] ];
          };
        };
      };
    };
  };
}
