{ mkShell
, pkgs
, ...
}:
mkShell {
  buildInputs = with pkgs; [
    deadnix
    hydra-check
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
    snowfallorg.flake
    snowfallorg.frost
    snowfallorg.thaw
    statix
  ];

  shellHook = ''

    echo 🔨 Welcome to khanelinix


  '';

}
