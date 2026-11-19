{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.services.restic;
in
{
  options.khanelinix.services.restic = {
    enable = lib.mkEnableOption "configured restic backup and repository check jobs";

    backups = lib.mkOption {
      # Evaluate each job in the upstream submodule so its defaults can see the final job settings.
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = ''
        Named jobs using the NixOS `services.restic.backups` options. Jobs
        are passed to NixOS only when this capability is enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # The upstream submodule treats attribute sets as settings, not modules.
    services.restic.backups = lib.mapAttrs (_: job: lib.const job) cfg.backups;
  };
}
