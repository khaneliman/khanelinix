{ inputs, ... }:
_final: prev: {
  inherit (inputs.hyprland.packages.${prev.stdenv.hostPlatform.system})
    hyprland
    xdg-desktop-portal-hyprland
    ;
}
