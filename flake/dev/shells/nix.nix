{
  lib,
  mkShell,
  pkgs,
  ...
}:
let
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
in
mkShell {
  inherit packages;

  shellHook = ''
    echo "🔨 Nix DevShell"
    echo ""
    echo "📦 Available packages:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) packages}
    echo ""
    echo "💡 This shell contains advanced Nix development tools"
  '';
}
