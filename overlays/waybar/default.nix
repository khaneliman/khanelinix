{ ... }: final: prev:
{
  waybar-hyprland = prev.waybar-hyprland.overrideAttrs (oldAttrs: {
    version = "0.9.18";

    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = "0.9.18";
      hash = "sha256-bnaYNa1jb7kZ1mtMzeOQqz4tmBG1w5YXlQWoop1Q0Yc=";
    };

    mesonFlags = oldAttrs.mesonFlags ++ [ "-Dcava=disabled" ];
  });
}
