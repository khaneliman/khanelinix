_: _final: prev:
let
  libcava = rec {
    version = "0.10.1";
    src = prev.fetchFromGitHub {
      owner = "LukashonakV";
      repo = "cava";
      rev = version;
      hash = "sha256-iIYKvpOWafPJB5XhDOSIW9Mb4I3A4pcgIIPQdQYEqUw=";
    };
  };
in
{
  waybar = prev.waybar.overrideAttrs (_old: {
    version = "unstable-waybar";
    src = prev.fetchFromGitHub {
      owner = "Alexays";
      repo = "waybar";
      rev = "efb2eb5073a382a058477a25e1d8823f277104d5";
      hash = "sha256-wyapTjx7lrkfzKtGX8H3ybkxZK9kzZETOc+BnfDC2Zs=";
    };
    mesonFlags = prev.lib.remove "-Dgtk-layer-shell=enabled" prev.waybar.mesonFlags;

    postUnpack = ''
      pushd "$sourceRoot"
      cp -R --no-preserve=mode,ownership ${libcava.src} subprojects/cava-${libcava.version}
      patchShebangs .
      popd
    '';
  });
}
