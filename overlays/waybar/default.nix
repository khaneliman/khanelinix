{ ... }: _final: prev: {
  waybar = prev.waybar.overrideAttrs (_oldAttrs: {
    version = "8eb614f69edffb52ba57b381d99dce1f587235ec";

    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = "8eb614f69edffb52ba57b381d99dce1f587235ec";
      hash = "sha256-N18eRsEXrvUMsoz8uoXaT0VubNumTrzCI3Zwm9iwq8I=";
    };
  });
}
