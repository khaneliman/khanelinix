{ config
, lib
, options
, ...
}:
let
  cfg = config.khanelinix.services.snapper;

  safeStr = types.strMatching "[^\n\"]*" // {
    description = "string without line breaks or quotes";
    descriptionClass = "conjunction";
  };

  inherit (lib) types mkEnableOption mkIf;
in
{
  options.khanelinix.services.snapper = {
    enable = mkEnableOption "snapper";

    configs = lib.mkOption {
      default = { };
      description = "Subvolume configuration. Any option mentioned in man:snapper-configs(5)
        is valid here, even if NixOS doesn't document it.";
      type = types.attrsOf (types.submodule {
        freeformType = types.attrsOf (types.oneOf [ (types.listOf safeStr) types.bool safeStr types.number ]);
      });
    };
  };

  config = mkIf cfg.enable {
    services.snapper = {
      inherit (cfg) configs;

      snapshotRootOnBoot = true;
    };
  };
}

