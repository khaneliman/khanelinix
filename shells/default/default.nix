{
  inputs,
  mkShell,
  pkgs,
  system,
  namespace,
  ...
}:
mkShell {
  packages = with pkgs; [
    act
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
    # FIXME: IFD in upstream source flake.sh
    # snowfall-flake.packages.${system}.flake

    # Adds all the packages required for the pre-commit checks
    inputs.self.checks.${system}.pre-commit-hooks.enabledPackages
  ];

  shellHook = ''
    ${inputs.self.checks.${system}.pre-commit-hooks.shellHook}
    echo 🔨 Welcome to ${namespace}


  '';
}
