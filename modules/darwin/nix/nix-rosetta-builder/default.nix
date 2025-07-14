{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.nix.nix-rosetta-builder;
in
{
  options.khanelinix.nix.nix-rosetta-builder = {
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
    sshProtocol = lib.mkOption {
      type = lib.types.str;
      default = "ssh";
      description = "SSH protocol to use for the builder.";
    };
    speedFactor = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Speed factor for the builder.";
    };
  };

  config = {
    nix-rosetta-builder = {
      inherit (cfg)
        enable
        cores
        memory
        speedFactor
        sshProtocol
        ;

      onDemand = true;
      onDemandLingerMinutes = 30;
      permitNonRootSshAccess = true;
    };
  };
}
