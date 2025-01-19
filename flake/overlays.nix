{ inputs, lib, ... }:
let
  children =
    dir:
    lib.pipe dir [
      builtins.readDir
      builtins.attrNames
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
