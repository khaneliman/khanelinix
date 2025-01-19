{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      scope = lib.makeScope pkgs.newScope (_: {
        inherit inputs;
      });

      flattenAttrs =
        attrs:
        let
          flatten =
            attrSet: prefixes:
            builtins.foldl' (
              acc: name:
              let
                newKey = prefixes ++ [ name ];
                packageFn = if lib.isFunction attrSet.${name} then attrSet.${name} scope.callPackage else null;
                package = if packageFn != null then packageFn else null;
                supported =
                  package != null
                  && (!(package ? meta.platforms) || lib.meta.availableOn pkgs.stdenv.hostPlatform package);
              in
              if lib.isFunction attrSet.${name} then
                (if supported then acc // { ${lib.concatStringsSep "/" newKey} = packageFn; } else acc)
              else
                acc // (flatten attrSet.${name} newKey)

            ) { } (builtins.attrNames attrSet);
        in
        flatten attrs [ ];

      directory = ../packages;
    in
    {
      legacyPackages = lib.filesystem.packagesFromDirectoryRecursive {
        inherit directory;
        inherit (scope) callPackage;
      };

      packages = flattenAttrs (
        lib.filesystem.packagesFromDirectoryRecursive {
          inherit directory;
          callPackage =
            file: args: callback:
            callback file args;
        }
      );
    };
}
