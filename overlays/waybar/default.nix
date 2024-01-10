_: _final: prev: {
  waybar = prev.waybar.overrideAttrs (old: {
    version = "unstable-waybar";
    src = prev.fetchFromGitHub {
      owner = "Syndelis";
      repo = "waybar";
      rev = "9e08512927d2de34a55281ee7fc3f13c36c6c9c5";
      sha256 = "sha256-7hyOmMTkvQ1a7yQ4YA5Kheg9FLUAPV3otvDj7kGKgko=";
    };

    patches = [ ./catch.patch ];
  });
}
