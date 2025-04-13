{
  mkShell,
  pkgs,
  namespace,
  ...
}:
mkShell {
  packages = with pkgs; [
    deadnix
    hydra-check
    nh
    nix-bisect
    nix-diff
    nix-fast-build
    nix-health
    nix-index
    nix-inspect
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
    echo 🔨 Welcome to ${namespace}


  '';
}
