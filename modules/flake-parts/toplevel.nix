{
  inputs,
  lib,
  self,
  ...
}:

{
  imports = [
    inputs.nixos-unified.flakeModules.default
    inputs.nixos-unified.flakeModules.autoWire
  ];
  perSystem =
    {
      self',
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = lib.attrValues self.overlays;
        config = {
          # allowBroken = true;
          allowUnfree = true;
          # showDerivationWarnings = [ "maintainerless" ];

          permittedInsecurePackages = [
            # NOTE: needed by emulationstation
            "freeimage-unstable-2021-11-01"
            # dev shells
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
      };

      packages.default = self'.packages.activate;
    };
}
