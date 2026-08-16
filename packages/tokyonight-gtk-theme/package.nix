{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gnome-shell,
  sassc,
  gnome-themes-extra,
  ...
}:

stdenvNoCC.mkDerivation {
  pname = "tokyonight-gtk-theme";
  version = "0-unstable-2025-10-23";

  src = fetchFromGitHub {
    owner = "Fausto-Korpsvart";
    repo = "Tokyonight-GTK-Theme";
    rev = "6c340e058e84c1975a038a8e5d1e384477225dc0";
    hash = "sha256-7H2n9wTaW8Db1RejWK071ITV1j5KIuzfql0Tx9WT6zM=";
  };

  nativeBuildInputs = [
    gnome-shell
    sassc
  ];
  buildInputs = [ gnome-themes-extra ];

  dontBuild = true;

  postPatch = ''
    patchShebangs themes/install.sh
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/themes"
    cd themes
    ./install.sh -n Tokyonight -d "$out/share/themes"

    runHook postInstall
  '';

  postInstall = ''
    # GTK3 and GTK4 do not need the removed GTK2 murrine engine.
    find "$out/share/themes" -type d -name gtk-2.0 -prune -exec rm -rf {} +
  '';

  meta = {
    description = "GTK theme based on the Tokyo Night colour palette";
    homepage = "https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme";
    license = lib.licenses.gpl3Plus;
    maintainers = [ lib.maintainers.khaneliman ];
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
