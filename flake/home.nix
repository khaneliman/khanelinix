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
    _name:
    args@{
      system,
      username,
      userAtHost,
      hostname,
      ...
    }:
    let
      configPath = args.path;
    in
    {
      name = userAtHost; # Use the full "username@hostname" as key
      value = self.lib.system.mkHome {
        inherit
          inputs
          system
          hostname
          username
          ;
        modules = [ configPath ];
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
