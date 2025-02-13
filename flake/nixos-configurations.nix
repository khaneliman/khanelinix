{
  self,
  inputs,
  lib,
  ...
}:
let
  inherit (builtins) readDir attrNames mapAttrs;

  configDirs =
    let
      dirs = readDir ../configurations/nixos;
      dirNames = lib.filterAttrs (name: type: type == "directory") dirs;
    in
    attrNames dirNames;

  # Create a NixOS system configuration
  mkSystem = name: {
    inherit (inputs.nixpkgs.lib) nixosSystem;

    specialArgs = { inherit self inputs; };

    modules = [
      ../configurations/${name}/default.nix
      self.nixosModules.common
      self.nixosModules.nixos
    ];
  };

  # Create all system configurations
  nixosConfigurations = lib.genAttrs configDirs (
    name: inputs.nixpkgs.lib.nixosSystem (mkSystem name)
  );
in
{
  flake = {
    inherit nixosConfigurations;
  };
}
