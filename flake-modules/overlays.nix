{ inputs, lib, ... }:
{
  flake.overlays = lib.listToAttrs (
    map (file: {
      name = "${builtins.hashString "sha256" file}-overlay";
      value = import file { flake = inputs.self; };
    }) (inputs.self.lib.khanelinix.readAllFiles ../overlays)
  );
}
