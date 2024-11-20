{ lib, inputs, ... }:
{
  imports =
    [ ./devshell.nix ]
    ++ lib.optional (inputs.pre-commit-hooks-nix ? flakeModule) inputs.pre-commit-hooks-nix.flakeModule
    ++ lib.optional (inputs.treefmt-nix ? flakeModule) inputs.treefmt-nix.flakeModule;

  perSystem =
    {
      lib,
      pkgs,
      ...
    }:
    lib.optionalAttrs (inputs.treefmt-nix ? flakeModule) {
      treefmt.config = {
        projectRootFile = "flake.nix";
        flakeCheck = true;

        programs = {
          actionlint.enable = true;
          clang-format.enable = true;
          isort.enable = true;
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
          };
          prettier = {
            enable = true;

            excludes = [ "**.md" ];
          };
          ruff = {
            check = true;
            format = true;
          };
          statix.enable = true;
          stylua.enable = true;
          shfmt.enable = true;
          taplo.enable = true;
        };

        settings = {
          global.excludes = [
            ".editorconfig"
            ".envrc"
            ".git-blame-ignore-revs"
            ".gitignore"
            "LICENSE"
            "flake.lock"
            "**.md"
            "**.scm"
            "**.svg"
            "**/man/*.5"
          ];
          formatter.ruff-format.options = [ "--isolated" ];
        };
      };
    }
    // lib.optionalAttrs (inputs.pre-commit-hooks-nix ? flakeModule) {
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
