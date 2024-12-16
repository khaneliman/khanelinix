{
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs) pre-commit-hooks-nix;
in
pre-commit-hooks-nix.lib.${pkgs.system}.run {
  src = ./.;
  hooks = {
    actionlint.enable = true;

    biome.enable = true;

    clang-format.enable = true;

    clang-tidy.enable = true;

    deadnix = {
      enable = true;

      settings = {
        edit = true;
      };
    };

    denofmt = {
      enable = true;
      excludes = [
        ".*.ts$"
        ".*.js$"
      ];
    };

    isort.enable = true;

    luacheck.enable = true;

    nixfmt-rfc-style.enable = true;

    pre-commit-hook-ensure-sops.enable = true;

    ruff.enable = true;

    rustfmt.enable = true;

    shfmt = {
      enable = true;

      excludes = [ ".*.p10k.zsh$" ];
    };

    statix.enable = true;

    stylua.enable = true;

    # treefmt.enable = true;

    yamlfmt.enable = true;
  };
}
