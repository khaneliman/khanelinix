{
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (self.lib.file) parseHomeConfigurations;

  homesPath = ../homes;
  allHomes = parseHomeConfigurations homesPath;

  generateHomeConfiguration =
    name:
    {
      system,
      username,
      userAtHost,
      hostname,
      path,
      ...
    }:
    {
      name = userAtHost; # Use the full "username@hostname" as key
      value = self.lib.system.mkHome {
        inherit
          inputs
          system
          hostname
          username
          ;
        modules = [ path ];
      };
    };
in
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake = {
    homeModules = {
      default = ../modules/home;
    };

    # Dynamically generated home configurations
    homeConfigurations = lib.mapAttrs' generateHomeConfiguration allHomes;
  };
}
