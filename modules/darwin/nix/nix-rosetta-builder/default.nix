{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.nix.nix-rosetta-builder;
in
{
  options.${namespace}.nix.nix-rosetta-builder = {
    enable = lib.mkEnableOption "nix-rosetta-builder";
    cores = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Number of cores to use for the builder.";
    };
    memory = lib.mkOption {
      type = lib.types.str;
      default = "8GiB";
      description = "Memory to use for the builder.";
    };
  };

  config = {
    nix-rosetta-builder = {
      inherit (cfg) enable cores memory;

      onDemand = true;
      onDemandLingerMinutes = 30;
      permitNonRootSshAccess = true;
    };
  };
}
