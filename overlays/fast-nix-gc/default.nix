{ inputs }:
_final: prev: {
  fast-nix-optimise = inputs.fast-nix-gc.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (
    old: {
      patches = (old.patches or [ ]) ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
        ./skip-executables.patch
      ];
    }
  );
}
