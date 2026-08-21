{
  fetchFromGitHub,
  lib,
  makeWrapper,
  nix-update-script,
  python3,
  stdenv,

  ...
}:
let
  # The engine is pure C. Python only launches it, plans placement, and serves
  # the optional API, and those import nothing beyond the standard library and
  # numpy. Conversion tools need torch, safetensors, and huggingface-hub, so
  # they stay out of the runtime closure.
  pythonEnv = python3.withPackages (ps: [ ps.numpy ]);

  # A distributed binary must not carry -march=native, which would pin it to
  # this builder and break substitution.
  archBaseline = if stdenv.hostPlatform.isx86_64 then "x86-64-v3" else "armv8-a";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "colibri";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "JustVugg";
    repo = "colibri";
    rev = "33e67a9c004b6e608d1f19dfbdcc20793377f94f";
    hash = "sha256-f1IHa87lUBYgKXfX0EivxCvSb7bjb2JRt9IhFjoSe5Y=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # libgomp belongs to the runtime closure because the engine is an OpenMP
  # build.
  buildInputs = [ stdenv.cc.cc.lib ];

  buildPhase = ''
    runHook preBuild

    # The install target copies qwen36 without listing it as a prerequisite, so
    # build that engine first. Drop this once upstream fixes the rule.
    make -C c qwen36 ARCH=${archBaseline}

    # `make install` builds the remaining engines, then stages each beside coli
    # so its directory-relative dispatch resolves them.
    make -C c install ARCH=${archBaseline} \
      DESTDIR=$out PREFIX= BINDIR=/bin LIBEXECDIR=/lib/colibri

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # openai_server.py imports v4_dsml unconditionally and iq3_pack.py reads
    # the grid asset, but the upstream file lists stage neither. Each guard
    # defers to a release that installs them itself.
    [ -e "$out/lib/colibri/v4_dsml.py" ] \
      || install -m 644 c/v4_dsml.py "$out/lib/colibri/"
    [ -e "$out/lib/colibri/tools/iq3xxs_grid.json" ] \
      || install -m 644 c/tools/iq3xxs_grid.json "$out/lib/colibri/tools/"

    # coli dispatches relative to its own directory, so it moves beside the
    # engines and $out/bin/coli becomes the wrapper.
    mv $out/bin/coli $out/lib/colibri/coli
    ln -s ../lib/colibri/colibri $out/bin/colibri

    # COLI_ENGINE stays unset on purpose: engine_for() routes every model to
    # the GLM engine whenever it is present, which defeats per-model dispatch.
    makeWrapper ${lib.getExe pythonEnv} $out/bin/coli \
      --add-flags "$out/lib/colibri/coli" \
      --set PYTHONPATH "$out/lib/colibri:${pythonEnv}/${python3.sitePackages}"

    runHook postInstall
  '';

  # The upstream C tests measure SSD probe timing and io_uring, which a sandbox
  # cannot reproduce. Check the installed layout instead.
  doCheck = false;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    # An install check must not mutate $out, so block the .pyc these writes.
    export PYTHONDONTWRITEBYTECODE=1

    for engine in colibri olmoe qwen36; do
      test -x "$out/lib/colibri/$engine"
    done
    test -f $out/lib/colibri/tools/iq3xxs_grid.json

    # argparse exits before any model load.
    $out/bin/coli --version
    PYTHONPATH=$out/lib/colibri ${lib.getExe pythonEnv} -c 'import openai_server'

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Run large mixture-of-experts models in pure C with experts streamed from disk";
    homepage = "https://github.com/JustVugg/colibri";
    changelog = "https://github.com/JustVugg/colibri/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "coli";
    platforms = lib.platforms.unix;
  };
})
