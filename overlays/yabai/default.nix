{ inputs }:
_final: prev:
let
  yabaiPatch = prev.fetchpatch2 {
    name = "nixpkgs-pr-353182-yabai";
    url = "https://github.com/NixOS/nixpkgs/pull/353182.patch";
    hash = "sha256-x1eEc3WFXnSuy7uyPnthU2QbWhDX2NnTjmP526GJNzE=";
  };

  patchedNixpkgs = prev.applyPatches {
    name = "nixpkgs-yabai-pr-353182";
    src = inputs.nixpkgs-unstable;
    patches = [ yabaiPatch ];
  };
in
{
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/353182 lands.
  yabai = prev.callPackage "${patchedNixpkgs}/pkgs/by-name/ya/yabai/package.nix" { };
}
