{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-small)
    blender
    clamav
    dupeguru
    mysql-workbench
    rocmPackages
    swiftPackages
    ;
}
