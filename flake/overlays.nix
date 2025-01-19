{ inputs, lib, ... }:
let
  children =
    dir:
    with builtins;
    lib.pipe dir [
      readDir
      attrNames
      (map (name: dir + "/${name}"))
    ];
in
{
  flake.overlays = lib.listToAttrs (
    map (file: {
      name = "${lib.removeSuffix ".nix" (builtins.hashString "sha256" (builtins.readFile file))}-overlay";
      value = import file { flake = inputs.self; };
    }) (children ../overlays)
  );
}
