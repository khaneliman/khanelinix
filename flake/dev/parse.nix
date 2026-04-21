_: {
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        parseNix = pkgs.callPackage ../../ci/parse.nix {
          nix = pkgs.nixVersions.latest;
        };
        parseLix = pkgs.callPackage ../../ci/parse.nix {
          nix = pkgs.lixPackageSets.latest.lix;
        };
      };
    };
}
