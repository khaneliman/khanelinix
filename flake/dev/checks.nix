{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = lib.optional (inputs.git-hooks-nix ? flakeModule) inputs.git-hooks-nix.flakeModule;

  perSystem =
    { pkgs, ... }:
    {
      pre-commit = lib.mkIf (inputs.git-hooks-nix ? flakeModule) {
        check.enable = false;

        settings.hooks = {
          clang-tidy.enable = true;
          eslint = {
            enable = true;
            package = pkgs.eslint_d;
          };
          luals = {
            enable = true;
            description = "LuaLS diagnostics";
            entry = "${lib.getExe pkgs.lua-language-server} --configpath=.luarc.json --check=. --check_format=pretty --checklevel=Warning";
            files = "\\.lua$";
            language = "system";
            pass_filenames = false;
          };
          pre-commit-hook-ensure-sops.enable = true;
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

      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (
        lib.mapAttrs' (name: cfg: {
          name = "darwin-${name}";
          value = cfg.system;
        }) self.darwinConfigurations
      );
    };
}
