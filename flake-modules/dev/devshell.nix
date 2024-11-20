{ lib, inputs, ... }:
{
  imports = lib.optional (inputs.devshell ? flakeModule) inputs.devshell.flakeModule;

  perSystem =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    lib.optionalAttrs (inputs.devshell ? flakeModule) {
      devshells.default = {
        devshell.startup.pre-commit.text = config.pre-commit.installationScript;

        commands = [
          {
            name = "checks";
            help = "Run all checks";
            command = ''
              echo "=> Running all checks..."

              nix flake check "$@"
            '';
          }
          {
            name = "format";
            help = "Format the entire codebase";
            command = "nix fmt";
          }
          {
            name = "docs";
            help = "Build khanelinix documentation";
            command = ''
              echo "=> Building khanelinix documentation..."

              ${pkgs.lib.getExe pkgs.nix-output-monitor} build .#docs "$@"
            '';
          }
          {
            name = "serve-docs";
            help = "Build and serve documentation locally";
            command = ''
              echo -e "=> Building khanelinix documentation...\n"

              doc_derivation=$(${pkgs.lib.getExe pkgs.nix-output-monitor} build .#docs --no-link --print-out-paths)

              echo -e "\n=> Documentation successfully built ('$doc_derivation')"

              echo -e "\n=> You can then open your browser to view the doc\n"

              (cd "$doc_derivation"/share/doc && ${pkgs.lib.getExe pkgs.python3} ${./server.py})
            '';
          }
        ];
      };
    };
}
