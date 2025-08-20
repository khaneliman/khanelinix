_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      apps = {
        update-all = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "update-all";
              meta.mainProgram = "update-all";
              text = ''
                set -euo pipefail

                echo "🔄 Updating main flake lock..."
                nix flake update

                echo "🔄 Updating dev flake lock..."
                cd flake/dev && nix flake update

                echo "✅ All flake locks updated successfully!"
              '';
            }
          );
        };
      };
    };
}
