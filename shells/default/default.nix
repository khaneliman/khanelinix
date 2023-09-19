{ mkShell
, pkgs
, ...
}:
mkShell {
  buildInputs = with pkgs; [
    deadnix
    hydra-check
    nix-diff
    nix-index
    nix-prefetch-git
    nixpkgs-fmt
    nixpkgs-hammering
    nixpkgs-lint
    snowfallorg.flake
    snowfallorg.frost
    statix
  ];

  shellHook = ''

    echo 🔨 Welcome to khanelinix


  '';

}
