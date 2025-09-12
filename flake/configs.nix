{
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (self.lib.file) parseSystemConfigurations filterNixOSSystems filterDarwinSystems;

  systemsPath = ../systems;
  allSystems = parseSystemConfigurations systemsPath;
in
{
  flake = {
    nixosConfigurations = lib.mapAttrs' (
      _name:
      { system, hostname, ... }:
      {
        name = hostname;
        value = self.lib.system.mkSystem {
          inherit inputs system hostname;
          username = "khaneliman";
        };
      }
    ) (filterNixOSSystems allSystems);

    darwinConfigurations = lib.mapAttrs' (
      _name:
      { system, hostname, ... }:
      {
        name = hostname;
        value = self.lib.system.mkDarwin {
          inherit inputs system hostname;
          username = "khaneliman";
        };
      }
    ) (filterDarwinSystems allSystems);

    # NOTE: Home Manager configurations are now handled by flake/home.nix
  };
}
