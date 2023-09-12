{ mkShell
, pkgs
, ...
}:
mkShell {
  buildInputs = with pkgs; [
    nix-index
    nix-prefetch-git
    nixpkgs-fmt
    nixpkgs-hammering
    nixpkgs-lint
  ];

  shellHook = ''

    echo 🔨 Welcome to khanelinix


  '';

}
