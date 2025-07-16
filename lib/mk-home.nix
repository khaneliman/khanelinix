{ inputs }:
{
  system,
  hostname,
  username ? "khaneliman",
  modules ? [ ],
  ...
}:
let
  flake = inputs.self or (throw "mkHome requires 'inputs.self' to be passed");
  common = import ./common.nix { inherit inputs; };

  extendedLib = common.mkExtendedLib flake inputs.nixpkgs;
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs =
    import inputs.nixpkgs {
      inherit system;
    }
    // common.mkNixpkgsConfig flake;

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
    { _module.args.lib = extendedLib; }

    inputs.catppuccin.homeModules.catppuccin
    inputs.hypr-socket-watch.homeManagerModules.default
    inputs.nix-index-database.homeModules.nix-index
    inputs.sops-nix.homeManagerModules.sops

    ../modules/home
  ] ++ modules;
}
