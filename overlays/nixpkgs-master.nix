{ flake }:
_self: super: {
  inherit (flake.inputs.nixpkgs-master.legacyPackages.${super.stdenv.system})
    hyprland
    hyprland-qt-support
    hyprpolkitagent
    hyprsysteminfo
    xdg-desktop-portal-hyprland
    ;
}
