{ self, ... }:
final: _prev: {
  catppuccin-sddm-corners = self.inputs.catppuccin-sddm-corners.packages.${final.system}.default;
}
