{ lib, inputs, ... }:
{
  imports = lib.optional (inputs.treefmt-nix ? flakeModule) inputs.treefmt-nix.flakeModule;

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
    };
}
