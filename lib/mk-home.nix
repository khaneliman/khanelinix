{ inputs }:
{
  system,
  hostname,
  username ? "khaneliman",
  modules ? [ ],
  ...
}:
let
  # Import the khaneliparts flake to access the overlay
  flake = inputs.self or (throw "mkHome requires 'inputs.self' to be passed");

  # Extend nixpkgs lib with khanelinix functions
  extendedLib = inputs.nixpkgs-unstable.lib.extend flake.lib.overlay;
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs-unstable {
    inherit system;
    overlays = builtins.attrValues flake.overlays;
    config = {
      allowUnfree = true;
      # TODO: cleanup when available
      permittedInsecurePackages = [
        # NOTE: citrix
        "libxml2-2.13.8"
        # NOTE: needed by emulationstation
        "freeimage-3.18.0-unstable-2024-04-18"
        # dev shells
        "aspnetcore-runtime-6.0.36"
        "aspnetcore-runtime-7.0.20"
        "aspnetcore-runtime-wrapped-7.0.20"
        "aspnetcore-runtime-wrapped-6.0.36"
        "dotnet-combined"
      ];
    };
  };

  extraSpecialArgs = {
    inherit
      inputs
      hostname
      username
      system
      ;
    inherit (flake) self;
    lib = extendedLib;
    flake-parts-lib = inputs.flake-parts.lib;
  };

  modules = [
    # Provide extended lib to all modules
    { _module.args.lib = extendedLib; }

    # Third-party home modules
    inputs.catppuccin.homeModules.catppuccin
    inputs.hypr-socket-watch.homeManagerModules.default
    inputs.nix-index-database.homeModules.nix-index
    inputs.sops-nix.homeManagerModules.sops

    # Base home modules
    ../modules/home

    # Additional modules passed as arguments
  ] ++ modules;
}
