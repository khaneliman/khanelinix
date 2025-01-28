{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    hyprland-qt-support
    hyprpolkitagent
    hyprsysteminfo
    ;
}
