{ self, ... }:
final: _prev: {
  hyprland = self.inputs.hyprland.packages.${final.system}.default;
}
