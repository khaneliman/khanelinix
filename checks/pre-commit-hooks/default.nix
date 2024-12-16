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
    clang-tidy.enable = true;
    luacheck.enable = true;
    pre-commit-hook-ensure-sops.enable = true;
    treefmt.enable = true;
    treefmt.settings.fail-on-change = false;
    treefmt.packageOverrides.treefmt = inputs.treefmt-nix.lib.mkWrapper pkgs ../../treefmt.nix;
  };
}
