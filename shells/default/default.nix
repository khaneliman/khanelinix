{
  inputs,
  mkShell,
  pkgs,
  system,
  ...
}:
let
  inherit (inputs)
    nix-inspect
    snowfall-flake
    snowfall-frost
    snowfall-thaw
    ;
in
mkShell {
  buildInputs = with pkgs; [
    deadnix
    hydra-check
    nix-inspect.packages.${system}.default
    nix-bisect
    nix-diff
    nix-health
    nix-index
    nix-melt
    nix-prefetch-git
    nix-search-cli
    nixfmt-rfc-style
    nixpkgs-hammering
    nixpkgs-lint
    snowfall-flake.packages.${system}.flake
    snowfall-frost.packages.${system}.frost
    snowfall-thaw.packages.${system}.thaw
    statix
  ];

  shellHook = ''

    echo 🔨 Welcome to khanelinix


  '';
}
