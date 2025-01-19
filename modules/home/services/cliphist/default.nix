{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.cliphist;
in
{
  options.khanelinix.services.cliphist = {
    enable = mkEnableOption "cliphist";

    systemdTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Systemd targets for cliphist
      '';
    };
  };

  config = mkIf cfg.enable {
    services = {
      cliphist = {
        enable = true;
        allowImages = true;
        inherit (cfg) systemdTargets;
      };
    };
  };
}
