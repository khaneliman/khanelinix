{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    hyprland
    hyprland-qt-support
    hyprpolkitagent
    hyprsysteminfo
    xdg-desktop-portal-hyprland
    ;
}
