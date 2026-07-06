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
  version = "0.3.1-unstable-2026-06-25";

  src = fetchFromGitHub {
    owner = "khaneliman";
    repo = "codexbar-waybar";
    rev = "87be28ddb59ecfdb873e6d743f29491fc73c0594";
    hash = "sha256-62c1kGCAlScgQiq5O9w9reECFw66GFuj8vRPBKzlbjw=";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    substituteInPlace codexbar-popup.py \
      --replace-fail ${lib.escapeShellArg iconSearch} ${lib.escapeShellArg iconReplacement}

    substituteInPlace codexbar.sh \
          --replace-fail '    [claude]=oauth' '    [claude]=oauth
        [antigravity]=cli' \
          --replace-fail '    echo "$body"
    }' '    # A freshly started agy server can answer before RetrieveUserQuotaSummary is
        # ready. CodexBar then falls back to placeholder model quotas (0/0, no
        # extraRateWindows), which makes Waybar look healthy while hiding weekly
        # Antigravity usage. Give the CLI source two readiness retries.
        if [[ "$p" == "antigravity" ]]; then
            for _ in 1 2; do
                if echo "$body" | jq -e "type == \"array\" and (.[0].error // null) == null and (.[0].usage.extraRateWindows // null) == null and ((.[0].usage.primary.usedPercent // 0) == 0) and ((.[0].usage.secondary.usedPercent // 0) == 0)" >/dev/null 2>&1; then
                    sleep "''${CODEXBAR_ANTIGRAVITY_RETRY_DELAY:-5}"
                    body="$(fetch_one "$p" "$primary")"
                else
                    break
                fi
            done
        fi

        echo "$body"
    }'

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
    homepage = "https://github.com/khaneliman/codexbar-waybar";
    license = lib.licenses.mit;
    mainProgram = "codexbar-waybar";
    platforms = lib.platforms.linux;
  };
}
