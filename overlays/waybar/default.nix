{...}: final: prev: {
  waybar-hyprland = prev.waybar-hyprland.overrideAttrs (oldAttrs: {
    version = "e4900db9a2e00e41f43e40d6a8d90c2466645c37";

    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = "e4900db9a2e00e41f43e40d6a8d90c2466645c37";
      hash = "sha256-SpVUxggn5dk857ORWXuLvSHEwAkCiBEpObP1GLH6Ggk=";
    };
  });
}
