{
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (self.lib.file) scanSystems filterNixOSSystems filterDarwinSystems;

  systemsPath = ../systems;
  allSystems = scanSystems systemsPath;
in
{
  flake = {
    nixosConfigurations = lib.mapAttrs' (
      name:
      { system, hostname, ... }:
      {
        name = hostname;
        value = self.lib.mkSystem {
          inherit inputs system hostname;
          username = "khaneliman";
        };
      }
    ) (filterNixOSSystems allSystems);

    darwinConfigurations = lib.mapAttrs' (
      name:
      { system, hostname, ... }:
      {
        name = hostname;
        value = self.lib.mkDarwin {
          inherit inputs system hostname;
          username = "khaneliman";
        };
      }
    ) (filterDarwinSystems allSystems);

    # NOTE: Home Manager configurations are now handled by flake/home.nix
  };
}
