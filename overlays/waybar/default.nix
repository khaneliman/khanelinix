_: _final: prev: {
  waybar = prev.waybar.overrideAttrs (old: {
    version = "unstable-waybar";
    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "waybar";
      rev = "f744d906becbf6d06a3d95fee37af5c32061d1aa";
      sha256 = "sha256-7hyOmMTkvQ1a7yQ4YA5Kheg9FLUAPV3otvDj7kGKgko=";
    };

    patches = [ ./catch.patch ];
  });
}
