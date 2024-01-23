_: _final: prev: {
  waybar = prev.waybar.overrideAttrs (old: {
    version = "unstable-waybar";
    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "waybar";
      rev = "0d9c4929988cc8443483400631157826069a388d";
      sha256 = "sha256-ozW4yGPdGY2WrVU0mxqkc0uFQUg8m6+S/JkALwDxRTw=";
    };

    patches = [ ./catch.patch ];
  });
}
