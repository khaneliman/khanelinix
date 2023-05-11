{ ... }: final: prev:
{
  # waybar-hyprland = prev.waybar-hyprland.overrideAttrs (oldAttrs: {
  #   src = prev.fetchFromGitHub {
  #     owner = "Alexays";
  #     repo = "Waybar";
  #     rev = "b06953757e1a72236c73ba2780ca8ada800c9047";
  #     hash = "sha256-LFZ7Kzj9//vKtdOyDCjuT/VvANcnY009uooQwAd0sAQ=";
  #   };
  #
  #   mesonFlags = oldAttrs.mesonFlags ++ [ "-Dlibcxx=true" ];
  # });
}
