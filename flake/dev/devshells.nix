{
  inputs,
  ...
}:
{
  perSystem =
    {
      pkgs,
      lib,
      self,
      self',
      system,
      config,
      ...
    }:
    let
      # Import the overlay configuration
      overlaysConfig = import ../overlays.nix {
        inherit inputs lib self;
      };

      # Custom pkgs with insecure packages allowed for devshells
      # Use the existing pkgs but allow insecure packages by creating a new instance
      devPkgs = import pkgs.path {
        inherit (pkgs.stdenv.hostPlatform) system;
        config = pkgs.config // {
          allowUnfree = true;
          permittedInsecurePackages = pkgs.config.permittedInsecurePackages or [ ];
        };
        overlays = lib.attrValues overlaysConfig.flake.overlays;
      };

      shellsPath = ./shells;
      shellFiles = lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "dotnet.nix" # Handle dotnet specially
      ) (builtins.readDir shellsPath);
      shellNames = lib.mapAttrsToList (name: _: lib.removeSuffix ".nix" name) shellFiles;

      # Import dotnet shells (special case that generates multiple shells)
      dotnetShells = import (shellsPath + "/dotnet.nix") {
        inherit lib devPkgs;
      };

      buildShell = name: {
        ${name} = import (shellsPath + "/${name}.nix") {
          inherit
            config
            inputs
            lib
            self
            self'
            system
            ;
          inherit (devPkgs) mkShell;
          pkgs = devPkgs;
        };
      };
    in
    {
      devShells = lib.foldl' (acc: name: acc // buildShell name) dotnetShells shellNames;
    };
}
