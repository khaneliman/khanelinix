{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.services.cliphist;
in
{
  options.${namespace}.services.cliphist = {
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
      };
    };

    systemd.user.services.cliphist.Install.WantedBy = cfg.systemdTargets;
    systemd.user.services.cliphist-images.Install.WantedBy = cfg.systemdTargets;
  };
}
