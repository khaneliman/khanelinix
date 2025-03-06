_: _final: prev: {
  looking-glass-client =
    (prev.looking-glass-client.override { stdenv = prev.gcc13Stdenv; }).overrideAttrs
      (_oldAttrs: {
        rev = "B7";
        src = prev.fetchFromGitHub {
          owner = "gnif";
          repo = "LookingGlass";
          rev = "B7";
          hash = "sha256-I84oVLeS63mnR19vTalgvLvA5RzCPTXV+tSsw+ImDwQ=";
          fetchSubmodules = true;
        };

        patches = [ ];
        postInstall = ''
          mkdir -p $out/share/pixmaps
          cp $src/resources/lg-logo.png $out/share/pixmaps
        '';
      });
}
