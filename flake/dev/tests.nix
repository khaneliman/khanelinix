{
  inputs,
  lib,
  ...
}:
let
  hasNixUnit = inputs.nix-unit ? modules;
in
{
  imports = lib.optional hasNixUnit inputs.nix-unit.modules.flake.default;

  perSystem = _: {
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
