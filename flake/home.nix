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
      host =
        if lib.hasSuffix "-linux" system then
          self.nixosConfigurations.${hostname}
        else
          self.darwinConfigurations.${hostname};
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
        osConfig = host.config;
        inherit (host) pkgs;
        sharedHomeModules = host.config.home-manager.sharedModules;
        modules = [
          configPath
          (lib.mkAliasDefinitions host.options.khanelinix.home.extraOptions)
        ];
      };
    };
in
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake = {
    # Dynamically generated home configurations
    homeConfigurations = lib.mapAttrs' generateHomeConfiguration (
      self.lib.file.publicConfigurations "userAtHost" allHomes
    );
  };
}
