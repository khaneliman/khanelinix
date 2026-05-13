{ inputs }:
_final: prev: {
  inherit (inputs.hyprland.packages.${prev.stdenv.hostPlatform.system})
    hyprland
    hyprland-unwrapped
    xdg-desktop-portal-hyprland
    ;
}
