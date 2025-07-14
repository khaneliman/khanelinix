{
  inputs,
  lib,
  self,
  ...
}:
let
  overlaysPath = ../overlays;
  dynamicOverlaysSet =
    if builtins.pathExists overlaysPath then
      let
        overlayDirs = builtins.attrNames (builtins.readDir overlaysPath);
      in
      lib.genAttrs overlayDirs (
        name:
        let
          overlayPath = overlaysPath + "/${name}";
          overlayFn = import overlayPath;
        in
        if lib.isFunction overlayFn then
          overlayFn {
            inherit inputs;
            # Helper function to import nixpkgs with proper config
            mkPkgs =
              input: system: config:
              import input {
                inherit system config;
              };
          }
        else
          overlayFn
      )
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
          _name: func: final.callPackage func (self // { inherit inputs; })
        ) packageFunctions
      );
    };

  allOverlays = (lib.attrValues dynamicOverlaysSet) ++ [ khanelinixPackagesOverlay ];

in
{
  flake = {
    overlays = dynamicOverlaysSet // {
      default = khanelinixPackagesOverlay;
      khanelinix = khanelinixPackagesOverlay; # Alias for clarity
    };

    perSystem =
      { config, pkgs, ... }:
      {
        pkgs = pkgs.extend (lib.composeManyExtensions allOverlays);

        packages = config.pkgs.khanelinix // {
          inherit (self) packages;
        };
      };
  };
}
