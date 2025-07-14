{
  perSystem =
    {
      pkgs,
      lib,
      inputs,
      self,
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
        inherit (pkgs) system;
        config = pkgs.config // {
          allowUnfree = true;
          permittedInsecurePackages = (pkgs.config.permittedInsecurePackages or [ ]) ++ [
            # dotnet packages
            "aspnetcore-runtime-6.0.36"
            "aspnetcore-runtime-7.0.20"
            "aspnetcore-runtime-wrapped-7.0.20"
            "aspnetcore-runtime-wrapped-6.0.36"
            "dotnet-combined"
            "dotnet-core-combined"
            "dotnet-runtime-6.0.36"
            "dotnet-runtime-7.0.20"
            "dotnet-runtime-wrapped-6.0.36"
            "dotnet-runtime-wrapped-7.0.20"
            "dotnet-sdk-6.0.428"
            "dotnet-sdk-7.0.410"
            "dotnet-sdk-wrapped-6.0.428"
            "dotnet-sdk-wrapped-7.0.410"
            "dotnet-wrapped-combined"
          ];
        };
        overlays = [
          overlaysConfig.flake.overlays.khanelinix
        ];
      };

      shellsPath = ./shells;
      shellFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
        builtins.readDir shellsPath
      );
      shellNames = lib.mapAttrsToList (name: _: lib.removeSuffix ".nix" name) shellFiles;

      buildShell = name: {
        ${name} = import (shellsPath + "/${name}.nix") {
          inherit lib;
          inherit (devPkgs) mkShell;
          pkgs = devPkgs;
        };
      };

      dynamicShells = lib.foldl' (acc: name: acc // buildShell name) { } shellNames;
    in
    {
      devShells = dynamicShells // {
        default = pkgs.mkShell {
          name = "khanelidev";
          packages = with pkgs; [
            nixpkgs-fmt
            statix
            deadnix
            nil
          ];
          shellHook = ''
            echo "🚀 Khanelinix development environment"
            echo "Available commands:"
            echo "  nix flake check       - Run all checks"
            echo "  nix fmt -- --no-cache - Format without cache"
            echo "  statix check          - Check for anti-patterns"
            echo "  deadnix               - Find unused code"
          '';
        };
      };
    };
}
