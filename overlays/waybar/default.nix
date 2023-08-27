{ ... }: _final: prev: {
  waybar = prev.waybar.overrideAttrs (_oldAttrs: {
    version = "b66584308545e3da9fc4433529a684443b5eebe9";

    src = prev.fetchFromGitHub {
      owner = "khaneliman";
      repo = "Waybar";
      rev = "b66584308545e3da9fc4433529a684443b5eebe9";
      hash = "sha256-fMqAhogryl5sitDoGD2uOjZ1L6bTIFndcpH83gv3Fmo=";
    };
  });
}
