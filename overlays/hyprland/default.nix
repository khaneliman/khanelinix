{ self, ... }:
final: _prev: {
  inherit (self.inputs.hyprland.packages.${final.system})
    hyprland
    hyprland-debug
    hyprland-legacy-renderer
    hyprland-unwrapped
    xdg-desktop-portal-hyprland
    ;
}
