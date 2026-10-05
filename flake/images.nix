{
  inputs,
  self,
  lib,
  ...
}:
let
  images = {
    installer-minimal = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ../systems/x86_64-install-iso/minimal ];
    };
    rescue = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ../systems/x86_64-iso/rescue ];
    };
  };
in
{
  flake = {
    nixosConfigurations = images;
    referenceSources = {
      arm-vm = ../systems/aarch64-linux/nixos;
      installer-graphical = ../systems/x86_64-install-iso/graphical;
      isolated = ../systems/x86_64-iso/isolated;
    };
  };
  perSystem = { system, ... }: {
    packages = lib.optionalAttrs (system == "x86_64-linux") {
      installer-minimal-iso = self.nixosConfigurations.installer-minimal.config.system.build.isoImage;
      rescue-iso = self.nixosConfigurations.rescue.config.system.build.isoImage;
    };
  };
}
