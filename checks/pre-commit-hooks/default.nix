{
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs) git-hooks-nix;
in
git-hooks-nix.lib.${pkgs.system}.run {
  src = ./.;
  hooks = {
    clang-tidy.enable = true;
    luacheck.enable = true;
    pre-commit-hook-ensure-sops.enable = true;
    treefmt = {
      enable = true;
      settings.fail-on-change = false;
      packageOverrides.treefmt = inputs.treefmt-nix.lib.mkWrapper pkgs ../../treefmt.nix;
    };
  };
}
