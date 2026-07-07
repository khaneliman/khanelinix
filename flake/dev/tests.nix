{
  inputs,
  lib,
  ...
}:
let
  hasNamaka = inputs.namaka ? lib;
  hasNixUnit = inputs.nix-unit ? modules;
in
{
  imports = lib.optional hasNixUnit inputs.nix-unit.modules.flake.default;

  perSystem =
    { pkgs, ... }:
    {
      checks = lib.optionalAttrs hasNamaka {
        namaka-snapshots =
          let
            snapshotResult = inputs.namaka.lib.load {
              src = ../../lib/snapshot-tests;
              inputs = {
                khanelinix = inputs.self;
              };
            };
          in
          pkgs.runCommand "namaka-snapshots"
            {
              passAsFile = [ "snapshotResult" ];
              snapshotResult = builtins.toJSON snapshotResult;
            }
            ''
              cp "$snapshotResultPath" "$out"
            '';
      };

      nix-unit = lib.mkIf hasNixUnit {
        # `checks.<system>.nix-unit` evaluates root `self#tests` in the build
        # sandbox. Pass locked root inputs explicitly so the check stays offline.
        inputs = {
          inherit (inputs)
            fast-nix-gc
            flake-compat
            flake-parts
            hermes-agent
            home-manager
            nixpkgs
            nixpkgs-master
            nixpkgs-unstable
            sops-nix
            ;
        };
      };
    };
}
