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
            settings.config = {
              default = {
                extend-words = {
                  # Package name
                  ue = "ue";
                  ue4 = "ue4";
                  # Option name
                  browseable = "browseable";
                  # Application name
                  shotcut = "shotcut";
                  Shotcut = "Shotcut";
                };
                extend-ignore-re = [
                  # SSH public keys (ssh-rsa, ssh-ed25519, etc.)
                  "ssh-[a-z0-9]+ [A-Za-z0-9+/=]+"
                ];
              };
              files.extend-exclude = [
                "generated/*"
                "*.xsd"
                "*.svg"
                "*.yaml"
                "*.lock"
                "flake.lock"
                "package-lock.json"
                "*.png"
                "*.jpg"
                "*.jpeg"
                "*.gif"
                "*.ico"
                "*.webp"
                "*/nix/deps.nix"
                "*/ssh/hosts.nix"
                "custom.css"
              ];
            };
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
