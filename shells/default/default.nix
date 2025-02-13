{
  inputs,
  mkShell,
  pkgs,
  system,

  ...
}:
let
  inherit (inputs) snowfall-flake;
in
mkShell {
  packages = with pkgs; [
    act
    deadnix
    hydra-check
    nix-inspect
    nix-bisect
    nix-diff
    nix-health
    nix-index
    nix-melt
    nix-prefetch-git
    nix-search-cli
    nix-tree
    nixpkgs-hammering
    nixpkgs-lint
    snowfall-flake.packages.${system}.flake
    statix

    # Adds all the packages required for the pre-commit checks
    inputs.self.checks.${system}.pre-commit-hooks.enabledPackages
  ];

  shellHook = ''
    ${inputs.self.checks.${system}.pre-commit-hooks.shellHook}
    echo 🔨 Welcome to khanelinix


  '';
}
