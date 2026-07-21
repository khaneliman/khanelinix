{
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (self.lib.file)
    filterDarwinSystems
    filterNixOSSystems
    parseHomeConfigurations
    parseSystemConfigurations
    ;

  systemsPath = ../systems;
  homesPath = ../homes;
  allSystems = parseSystemConfigurations systemsPath;
  allHomes = parseHomeConfigurations homesPath;
  allNixosModules = self.lib.file.importModulesRecursive ../modules/nixos;
  allDarwinModules = self.lib.file.importModulesRecursive ../modules/darwin;
  matchingHomes =
    system: hostname:
    lib.filterAttrs (
      _name: homeConfig: homeConfig.system == system && homeConfig.hostname == hostname
    ) allHomes;
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
          nixosModules = allNixosModules;
          matchingHomes = matchingHomes system hostname;
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
          darwinModules = allDarwinModules;
          matchingHomes = matchingHomes system hostname;
        };
      }
    ) (filterDarwinSystems allSystems);

    # NOTE: Home Manager configurations are now handled by flake/home.nix
  };
}
