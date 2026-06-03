{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  callPackage,
  ...
}:

let
  # NixOS-runnable browsers pinned to the revisions this CLI's playwright-core
  # expects. Linux-only: darwin can run upstream downloads directly.
  browsers = if stdenv.hostPlatform.isLinux then callPackage ./browsers.nix { } else null;
in
buildNpmPackage rec {
  pname = "playwright-cli";
  version = "0.1.13";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "playwright-cli";
    rev = "v${version}";
    hash = "sha256-hHK/GR5Drlt+e0L9kyNmn+ht1PCrVH6WrVbxGB1Wsxg=";
  };

  npmDepsHash = "sha256-Ulp6IttsZcOOA7LaYDpVKkBYbe2j4RFG8lJARWifOSk=";

  # Ships playwright-cli.js directly; there is no compile step.
  dontNpmBuild = true;

  # The `playwright` dependency's postinstall fetches browsers over the network.
  # Skip it during the build; browsers are provided at runtime via
  # PLAYWRIGHT_BROWSERS_PATH (see postInstall) so the build stays offline/pure.
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  nativeBuildInputs = [ makeWrapper ];

  # Point the CLI at the nix-built, NixOS-runnable browsers and skip the host
  # requirement validation (it shells out to ldconfig, which is absent on NixOS).
  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram $out/bin/playwright-cli \
      --set-default PLAYWRIGHT_BROWSERS_PATH ${browsers} \
      --set-default PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS 1

    mv $out/bin/playwright-cli $out/bin/.playwright-cli-env
    cat > $out/bin/playwright-cli <<EOF
    #!${stdenv.shell}
    set -euo pipefail

    hasBrowser=0
    commandIndex=0
    commandName=
    skipNext=0
    index=0

    for arg in "\$@"; do
      index=\$((index + 1))

      case "\$arg" in
        --browser|--browser=*|-browser|-browser=*) hasBrowser=1 ;;
      esac

      if [ "\$commandIndex" -ne 0 ]; then
        continue
      fi

      if [ "\$skipNext" -eq 1 ]; then
        skipNext=0
        continue
      fi

      case "\$arg" in
        -s|--session)
          skipNext=1
          ;;
        -s=*|--session=*|--*)
          ;;
        -*)
          ;;
        *)
          commandIndex=\$index
          commandName=\$arg
          ;;
      esac
    done

    if [ "\$commandName" = open ] && [ "\$hasBrowser" -eq 0 ]; then
      set -- "\$@" --browser chromium
    fi

    exec "$out/bin/.playwright-cli-env" "\$@"
    EOF
    chmod +x $out/bin/playwright-cli
  '';

  passthru = lib.optionalAttrs stdenv.hostPlatform.isLinux { inherit browsers; };

  meta = {
    description = "Token-efficient CLI into Playwright for coding agents (snapshot, click, eval, run-code, sessions)";
    homepage = "https://github.com/microsoft/playwright-cli";
    license = lib.licenses.asl20;
    maintainers = [ ];
    platforms = lib.platforms.unix;
    mainProgram = "playwright-cli";
  };
}
