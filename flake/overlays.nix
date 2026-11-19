{
  inputs,
  lib,
  ...
}:
let
  overlaysPath = ../overlays;
  dynamicOverlaysSet =
    if builtins.pathExists overlaysPath then
      let
        overlayDirs = lib.filterAttrs (
          name: kind: kind == "directory" && builtins.pathExists (overlaysPath + "/${name}/default.nix")
        ) (builtins.readDir overlaysPath);
      in
      lib.mapAttrs (
        name: _:
        let
          overlayPath = overlaysPath + "/${name}";
          overlayFn = import overlayPath;
        in
        if lib.isFunction overlayFn then overlayFn { inherit inputs; } else overlayFn
      ) overlayDirs
    else
      { };

  khanelinixPackagesOverlay =
    final: prev:
    let
      directory = ../packages;
      packageFunctions = prev.lib.filesystem.packagesFromDirectoryRecursive {
        inherit directory;
        callPackage = file: _args: import file;
      };
    in
    {
      khanelinix = prev.lib.fix (
        self:
        prev.lib.mapAttrs (
          _name: package: final.callPackage (package.default or package) (self // { inherit inputs; })
        ) packageFunctions
      );
    };
in
{
  flake = {
    overlays = dynamicOverlaysSet // {
      default = khanelinixPackagesOverlay;
      firefox-addons = inputs.firefox-addons.overlays.default;
    };
  };
}
