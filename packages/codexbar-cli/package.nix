{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  curl,
  openssl,
  sqlite,
  procps,
  lsof,
  which,
  tzdata,
  ...
}:

let
  version = "0.56.5";

  sources = {
    x86_64-linux = {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-linux-x86_64.tar.gz";
      hash = "sha256-8HtyhYTn6d76aaMhhHMrcTJCxEBCHUrENSmkWUvZImI=";
    };
    aarch64-linux = {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-linux-aarch64.tar.gz";
      hash = "sha256-QTVIrRt48YXB4bHAifBQlllI2pG4oRhC89yptlETxNs=";
    };
    aarch64-darwin = {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-macos-arm64.tar.gz";
      hash = "sha256-inwik+qkvpIn911jk6DW3sQvX94eAeLYN3LOjesAVU8=";
    };
    x86_64-darwin = {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-macos-x86_64.tar.gz";
      hash = "sha256-/BMl3XGhBMsEF5SZxfV1nCYwvBNwAoiuaBozLmFYkOs=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "codexbar-cli is not packaged for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codexbar-cli";
  inherit version;

  src = fetchzip (source // { stripRoot = false; });

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    curl
    openssl
    sqlite
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/codexbar-cli $out/lib $out/libexec

    install -Dm0755 CodexBarCLI $out/bin/.codexbar-wrapped
    install -Dm0644 VERSION $out/share/codexbar-cli/VERSION

    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      # agy renders login and keyring status while it restores a valid token.
      # CodexBar 0.56.5 treats those transient lines as terminal auth failures
      # and kills agy before its local quota server is ready. Disable the early
      # PTY auth classification; CodexBar's existing 15-second readiness
      # timeout still bounds a genuinely unauthenticated session.
      grep -aFq 'Select login method:' $out/bin/.codexbar-wrapped
      grep -aFq 'select\s+login\s+method\s*:?' \
        $out/bin/.codexbar-wrapped
      grep -aFq 'you\s+are\s+not\s+logged\s+into\s+antigravity' \
        $out/bin/.codexbar-wrapped
      grep -aFq 'keyring\s*auth\s*:\s*timed\s+out\b' \
        $out/bin/.codexbar-wrapped
      LC_ALL=C sed -i \
        -e 's/Select login method:/Xxxxxx login method:/' \
        -e 's/select\\s+login\\s+method\\s\*:?/xxxxxx\\s+login\\s+method\\s*:?/' \
        -e 's/you\\s+are\\s+not\\s+logged\\s+into\\s+antigravity/zzz\\s+are\\s+not\\s+logged\\s+into\\s+antigravity/' \
        -e 's/keyring\\s\*auth\\s\*:\\s\*timed\\s+out\\b/xxxxxxx\\s*auth\\s*:\\s*timed\\s+out\\b/' \
        $out/bin/.codexbar-wrapped
      grep -aFq 'Xxxxxx login method:' $out/bin/.codexbar-wrapped
      grep -aFq 'xxxxxx\s+login\s+method\s*:?' \
        $out/bin/.codexbar-wrapped
      grep -aFq 'zzz\s+are\s+not\s+logged\s+into\s+antigravity' \
        $out/bin/.codexbar-wrapped
      grep -aFq 'xxxxxxx\s*auth\s*:\s*timed\s+out\b' \
        $out/bin/.codexbar-wrapped

      # 0.56.4 falls back to a /proc lookup when lsof fails on inaccessible
      # mount namespaces, so lsof only needs to resolve to a real binary.
      substitute ${./path-redirect.c.in} path-redirect.c \
        --replace-fail @ps@ ${lib.getExe' procps "ps"} \
        --replace-fail @lsof@ ${lib.getExe lsof} \
        --replace-fail @which@ ${lib.getExe which} \
        --replace-fail @tzdata@ ${tzdata}/share/zoneinfo

      $CC -shared -fPIC path-redirect.c -o $out/lib/codexbar-path-redirect.so -ldl -lssl -lcrypto

      makeWrapper $out/bin/.codexbar-wrapped $out/bin/codexbar \
        --set LD_PRELOAD $out/lib/codexbar-path-redirect.so
    ''}

    ${lib.optionalString (!stdenv.hostPlatform.isLinux) ''
      ln -s $out/bin/.codexbar-wrapped $out/bin/codexbar
    ''}

    runHook postInstall
  '';

  meta = {
    description = "CLI for CodexBar AI usage monitoring";
    homepage = "https://github.com/steipete/CodexBar";
    license = lib.licenses.mit;
    mainProgram = "codexbar";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
