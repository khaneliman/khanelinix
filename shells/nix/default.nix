{
  mkShell,
  pkgs,
  ...
}:
mkShell {
  packages = with pkgs; [
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
    nix-update
    nixpkgs-hammering
    nixpkgs-lint
    nixpkgs-review
    statix
  ];

  shellHook = ''
    echo 🔨 Welcome to khanelinix


  '';
}
