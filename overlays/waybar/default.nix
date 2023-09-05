{ ... }: _final: prev: {
  waybar = prev.waybar.overrideAttrs (_oldAttrs: {
    version = "80de22a15993d6ece7fbfa62858792a8c3fa207f";

    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = "80de22a15993d6ece7fbfa62858792a8c3fa207f";
      hash = "sha256-6T3mg11V8TpKuI52ss1Je26rW84qJdeEgapK7gBolBI=";
    };
  });
}
