{
  self,
  lib,
  ...
}:
let
  imageSystem = "x86_64-linux";
  inherit (self.lib.system.common.mkPatchedInputs { system = imageSystem; }) nixpkgs;
  images = {
    installer-minimal = nixpkgs.lib.nixosSystem {
      system = imageSystem;
      modules = [ ../systems/x86_64-install-iso/minimal ];
    };
    rescue = nixpkgs.lib.nixosSystem {
      system = imageSystem;
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
    packages = lib.optionalAttrs (system == imageSystem) {
      installer-minimal-iso = self.nixosConfigurations.installer-minimal.config.system.build.isoImage;
      rescue-iso = self.nixosConfigurations.rescue.config.system.build.isoImage;
    };
  };
}
