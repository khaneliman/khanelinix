{ stdenvNoCC, ... }:
stdenvNoCC.mkDerivation {
  name = "default-icon";
  src = ./profile.png;

  dontUnpack = true;

  installPhase = # bash
    ''
      cp $src $out
    '';

  passthru = {
    fileName = "profile.png";
  };
}
