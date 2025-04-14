{
  inputs,
  lib,
  namespace,
  ...
}:
let
  # Get all direct children of a directory
  children =
    dir:
    lib.pipe dir [
      builtins.readDir
      builtins.attrNames
      (map (name: dir + "/${name}"))
    ];

  # Process a file or directory to get overlay paths
  processPath =
    path:
    let
      pathType = builtins.typeOf path;
      isDirectory =
        pathType == "string" && builtins.pathExists path && builtins.readDir path ? "default.nix";
    in
    if isDirectory then path + "/default.nix" else path;

  # Get all overlay paths, including default.nix files in subdirectories
  getOverlayPaths =
    dir:
    let
      paths = children dir;
      processedPaths = map processPath paths;
    in
    builtins.filter (path: lib.hasSuffix ".nix" path) processedPaths;

  # Create an overlay that adds all packages to pkgs.${namespace}
  packagesOverlay = final: _prev: {
    ${namespace} = inputs.self.packages.${final.system} or { };
  };
in
{
  flake.overlays =
    # Add the packages overlay
    {
      ${namespace} = packagesOverlay;
    }
    # Add all other overlays from the overlays directory
    // lib.listToAttrs (
      map (file: {
        name = "${lib.removeSuffix ".nix" (builtins.hashString "sha256" (builtins.readFile file))}-overlay";
        value = import file { flake = inputs.self; };
      }) (getOverlayPaths ../overlays)
    );
}
