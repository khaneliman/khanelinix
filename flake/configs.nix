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
  allHomeModules = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.codex-desktop-linux.homeManagerModules.default
    inputs.nix-index-database.homeModules.nix-index
    inputs.plasma-manager.homeModules.plasma-manager
    inputs.sops-nix.homeManagerModules.sops
  ]
  ++ self.lib.file.importModulesRecursive ../modules/home;
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
          sharedHomeModules = allHomeModules;
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
          sharedHomeModules = allHomeModules;
          matchingHomes = matchingHomes system hostname;
        };
      }
    ) (filterDarwinSystems allSystems);

    # NOTE: Home Manager configurations are now handled by flake/home.nix
  };
}
