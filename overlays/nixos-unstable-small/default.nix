{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-small)
    blender
    clamav
    mysql-workbench
    rocmPackages
    swiftPackages
    ;
}
