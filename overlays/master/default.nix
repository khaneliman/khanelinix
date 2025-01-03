{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    rocmPackages_6
    ;
}
