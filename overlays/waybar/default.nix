{ ... }: _final: prev: {
  waybar = prev.waybar.overrideAttrs (oldAttrs: {
    version = "ee4fbc58f7ae52439c1a3af09fefed69a3a0d700";

    src = prev.fetchFromGitHub {
      owner = "khaneliman";
      repo = "Waybar";
      rev = "ee4fbc58f7ae52439c1a3af09fefed69a3a0d700";
      hash = "sha256-fMqAhogryl5sitDoGD2uOjZ1L6bTIFndcpH83gv3Fmo=";
    };
  });
}
