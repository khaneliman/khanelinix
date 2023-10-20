_: (_final: prev: {
  waybar = prev.waybar.overrideAttrs (old: {
    version = "2578";
    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "waybar";
      rev = "pull/2578/head";
      hash = "sha256-MuEOOQ8cO4MXMdRImh2dBiUtPJvSF22SICVKEsjCVRc=";
    };
  });
})
