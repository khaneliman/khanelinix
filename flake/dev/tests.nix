{
  inputs,
  lib,
  self,
  ...
}:
let
  hasNixUnit = inputs.nix-unit ? modules;
in
{
  imports = lib.optional hasNixUnit inputs.nix-unit.modules.flake.default;

  # Pure `lib.khanelinix` helper tests, run via `nix flake check` (check
  # `nix-unit`) or ad hoc with `nix-unit --flake .#tests` from the dev shell.
  # Cases live next to the library in `lib/tests`.
  flake.tests = lib.mkIf hasNixUnit (import ../../lib/tests { inherit self lib; });

  perSystem = _: {
    nix-unit = lib.mkIf hasNixUnit {
      # `checks.<system>.nix-unit` re-evaluates `self#tests` in the build
      # sandbox. Pass the primary inputs to avoid refetching them, and allow
      # network for the remaining transitive inputs this partitioned flake
      # drags in through its overlays (e.g. home-manager).
      inputs = {
        inherit (inputs) nixpkgs flake-parts nix-unit;
      };
      allowNetwork = true;
    };
  };
}
