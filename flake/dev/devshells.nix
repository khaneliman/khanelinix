{
  perSystem =
    { pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          name = "khanelidev";
          packages = with pkgs; [
            nixpkgs-fmt
            statix
            deadnix
            nil
          ];
          shellHook = ''
            echo "🚀 Khanelinix development environment"
            echo "Available commands:"
            echo "  nix flake check       - Run all checks"
            echo "  nix fmt -- --no-cache - Format without cache"
            echo "  statix check          - Check for anti-patterns"
            echo "  deadnix               - Find unused code"
          '';
        };
      };
    };
}
