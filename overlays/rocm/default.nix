{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-rocm)
    rocmPackages_6
    ;
}
