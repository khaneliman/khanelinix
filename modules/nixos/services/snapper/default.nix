{
  config,
  lib,
  options,

  ...
}:
let
  cfg = config.khanelinix.services.snapper;

  inherit (lib) mkEnableOption mkIf;
in
{
  options.khanelinix.services.snapper = {
    enable = mkEnableOption "snapper";

    configs = lib.mkOption {
      # Reuse the upstream type instead of restating it here.
      inherit (options.services.snapper.configs) type;
      default = { };
      description = "Subvolume configuration passed through to services.snapper.configs.";
    };
  };

  config = mkIf cfg.enable {
    services.snapper = {
      inherit (cfg) configs;

      snapshotRootOnBoot = true;
    };
  };
}
