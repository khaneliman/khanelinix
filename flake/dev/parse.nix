{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks = {
        parseNix = pkgs.callPackage ../../ci/parse.nix {
          # Parsing needs no download-authentication patch. Use upstream Nix
          # so this check does not rebuild Nix and its tests on CI runners.
          nix = inputs.nixpkgs.legacyPackages.${system}.nixVersions.latest;
        };
        parseLix = pkgs.callPackage ../../ci/parse.nix {
          nix = pkgs.lixPackageSets.latest.lix;
        };
      };
    };
}
