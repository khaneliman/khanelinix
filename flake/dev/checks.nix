{ inputs, lib, ... }:
{
  imports = lib.optional (inputs.git-hooks-nix ? flakeModule) inputs.git-hooks-nix.flakeModule;

  perSystem =
    { pkgs, ... }:
    {
      pre-commit = lib.mkIf (inputs.git-hooks-nix ? flakeModule) {
        check.enable = false;

        settings.hooks = {
          # FIXME: broken dependency on darwin
          actionlint.enable = pkgs.stdenv.hostPlatform.isLinux;
          clang-tidy.enable = true;
          deadnix = {
            enable = true;

            settings = {
              edit = true;
            };
          };
          eslint = {
            enable = true;
            package = pkgs.eslint_d;
          };
          luacheck.enable = true;
          pre-commit-hook-ensure-sops.enable = true;
          statix = {
            enable = true;
            # Only staged changes
            pass_filenames = true;
            entry = "${lib.getExe pkgs.bash} -c 'for file in \"$@\"; do ${lib.getExe pkgs.statix} check \"$file\"; done' --";
            language = "system";
          };
          treefmt.enable = true;
          typos = {
            enable = true;
            settings.ignored-words = [
              # Package name
              "ue"
              "ue4"
              # Option name
              "browseable"
              # Application name
              "shotcut"
              "Shotcut"
            ];
            excludes = [
              "generated/.*"
              ".*\\.xsd$"
              ".*\\.svg$"
              ".*\\.yaml$"
              ".*\\.lock$"
              "flake\\.lock$"
              "package-lock\\.json$"
              ".*\\.(png|jpg|jpeg|gif|ico|webp)$"
              ".*/nix/deps\\.nix$"
              ".*/ssh/hosts\\.nix$"
              "custom\\.css$"
            ];
          };
        };
      };

      checks = {
        # TODO:
        # Custom checks can go here
        # nix-syntax = pkgs.runCommand "check-nix-syntax" { } ''
        #   find ${./../..} -name "*.nix" -exec ${pkgs.nix}/bin/nix-instantiate --parse {} \; > /dev/null
        #   touch $out
        # '';
      };
    };
}
