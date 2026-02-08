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
      shellsPath = ./shells;
      shellFiles = lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "dotnet.nix" # Handle dotnet specially
      ) (builtins.readDir shellsPath);
      shellNames = lib.mapAttrsToList (name: _: lib.removeSuffix ".nix" name) shellFiles;

      # Import dotnet shells (special case that generates multiple shells)
      dotnetShells = import (shellsPath + "/dotnet.nix") {
        inherit lib pkgs;
      };

      buildShell = name: {
        ${name} = import (shellsPath + "/${name}.nix") {
          inherit
            config
            inputs
            lib
            pkgs
            self
            self'
            system
            ;
          inherit (pkgs) mkShell;
        };
      };
    in
    {
      devShells = lib.foldl' (acc: name: acc // buildShell name) dotnetShells shellNames;
    };
}
