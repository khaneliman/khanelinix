_: _final: prev: {
  waybar = prev.waybar.overrideAttrs (_old: {
    version = "unstable-waybar";
    src = prev.fetchFromGitHub {
      owner = "zjeffer";
      repo = "waybar";
      rev = "11310b89f063a305de0d23aa4dd21d6ef365a776";
      sha256 = "sha256-2NJRsx5VXh0BCfoEDfOvL0wMKR3uzpMWq8XSg4ZZ5rg=";
    };
  });
}
