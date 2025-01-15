{ lib, inputs, ... }:
{
  imports = lib.optional (inputs.git-hooks-nix ? flakeModule) inputs.git-hooks-nix.flakeModule;

  perSystem =
    {
      lib,
      pkgs,
      ...
    }:
    lib.optionalAttrs (inputs.git-hooks-nix ? flakeModule) {
      pre-commit = {
        check.enable = false;

        settings.hooks = {
          actionlint.enable = true;
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
          statix.enable = true;
          treefmt.enable = true;
          typos = {
            enable = true;
            excludes = [ "generated/*" ];
          };
        };
      };
    };
}
