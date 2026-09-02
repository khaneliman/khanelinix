{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  cairo,
  coreutils,
  gdk-pixbuf,
  glib,
  gobject-introspection,
  graphene,
  harfbuzz,
  gtk4,
  gtk4-layer-shell,
  jq,
  libnotify,
  pango,
  procps,
  python3,
  which,
  xdg-utils,
  ...
}:

let
  iconSearch = "ICONS_DIR = Path(\n    os.environ.get(\"XDG_DATA_HOME\", str(Path.home() / \".local/share\"))\n) / \"codexbar-waybar\" / \"icons\"";
  iconReplacement = "ICONS_DIR = Path(os.environ.get(\n    \"CODEXBAR_ICONS_DIR\",\n    str(Path(os.environ.get(\"XDG_DATA_HOME\", str(Path.home() / \".local/share\"))) / \"codexbar-waybar\" / \"icons\"),\n))";
  pythonEnv = python3.withPackages (
    pythonPackages: with pythonPackages; [
      pycairo
      pygobject3
    ]
  );
in
stdenvNoCC.mkDerivation {
  pname = "codexbar-waybar";
  version = "0.4.0-unstable-2026-08-29";

  src = fetchFromGitHub {
    owner = "Marouan-chak";
    repo = "codexbar-waybar";
    rev = "bf9dd73ca87152a073ae542e19f523ecf6eae2dd";
    hash = "sha256-fQHiMDhcxAGry9GW4Vg2edsmso2ZlwGjqVbq1j/Zsag=";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ jq ];

  patches = [
    ./provider-sources.patch
    ./cache-max-age.patch
    ./provider-sections.patch
  ];

  postPatch = ''
    substituteInPlace codexbar-popup.py \
      --replace-fail ${lib.escapeShellArg iconSearch} ${lib.escapeShellArg iconReplacement}
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    ${lib.getExe bash} ${./tests/cache-max-age.sh} \
      ./codexbar.sh \
      ${./tests/stale-cache.json} \
      ${lib.getExe bash} \
      ${lib.getExe' coreutils "false"}

    ${lib.getExe bash} ${./tests/provider-sources.sh} \
      ./codexbar.sh \
      ${./tests/fake-codexbar.sh} \
      ${lib.getExe bash}

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    install -Dm0755 codexbar.sh $out/bin/.codexbar-waybar-wrapped
    install -Dm0755 codexbar-popup.py $out/bin/.codexbar-waybar-popup-wrapped
    install -Dm0644 codexbar.css $out/share/codexbar-waybar/codexbar.css
    install -Dm0644 LICENSE $out/share/licenses/codexbar-waybar/LICENSE

    install -d $out/share/codexbar-waybar/icons
    install -m0644 assets/providers/ProviderIcon-*.svg $out/share/codexbar-waybar/icons/
    install -m0644 assets/providers/NOTICE $out/share/codexbar-waybar/icons/NOTICE

    makeWrapper $out/bin/.codexbar-waybar-wrapped $out/bin/codexbar.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          coreutils
          jq
        ]
      }

    ln -s $out/bin/codexbar.sh $out/bin/codexbar-waybar

    makeWrapper ${pythonEnv}/bin/python3 $out/bin/codexbar-waybar-popup \
      --add-flags $out/bin/.codexbar-waybar-popup-wrapped \
      --set CODEXBAR_ICONS_DIR $out/share/codexbar-waybar/icons \
      --set CODEXBAR_LAYER_SHELL_LIB ${gtk4-layer-shell}/lib/libgtk4-layer-shell.so \
      --prefix GI_TYPELIB_PATH : ${
        lib.makeSearchPath "lib/girepository-1.0" (
          map lib.getLib [
            gdk-pixbuf
            glib
            gobject-introspection
            graphene
            harfbuzz
            cairo
            gtk4
            gtk4-layer-shell
            pango
          ]
        )
      } \
      --prefix XDG_DATA_DIRS : ${
        lib.makeSearchPath "share" [
          gdk-pixbuf
          glib
          gtk4
          pango
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath (
          map lib.getLib [
            gdk-pixbuf
            glib
            graphene
            harfbuzz
            cairo
            gtk4
            gtk4-layer-shell
            pango
          ]
        )
      } \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          jq
          libnotify
          procps
          which
          xdg-utils
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Waybar custom module and GTK4 popover for CodexBar Linux CLI";
    homepage = "https://github.com/Marouan-chak/codexbar-waybar";
    license = lib.licenses.mit;
    mainProgram = "codexbar-waybar";
    platforms = lib.platforms.linux;
  };
}
