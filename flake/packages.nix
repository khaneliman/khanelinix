{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let

      packageFunctions = lib.filesystem.packagesFromDirectoryRecursive {
        directory = ../packages;
        callPackage = file: _args: import file;
      };

      builtPackages = lib.fix (
        self:
        lib.mapAttrs (
          _name: packageData:
          let
            packageFn = packageData.default or packageData;
          in
          pkgs.callPackage packageFn (
            self
            // {
              inherit inputs;
            }
          )
        ) packageFunctions
      );

    in
    {
      # Keep packages lazy. Eager platform filtering here forces full package
      # evaluation and slows unrelated config eval.
      packages = builtPackages;
    };
}
