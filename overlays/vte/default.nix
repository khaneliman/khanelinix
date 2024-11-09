{ channels, ... }:
_final: _prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/353204 is available
  inherit (channels.nixpkgs-unstable) vte;
}
