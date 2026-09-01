{
  fetchFromGitHub,
  lib,
  makeWrapper,
  nix-update-script,
  python3,
  rocmPackages,
  stdenv,
  symlinkJoin,
  util-linux,
  writeShellScriptBin,

  # The GPU expert tier is opt-in. Without it the engine is pure CPU, which is
  # what upstream ships by default.
  hipSupport ? false,
  # rocm_agent_enumerator cannot run in the build sandbox, so HIP_ARCH=native is
  # unavailable and the target must be named.
  hipArch ? "gfx1100",

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

  # The Makefile expects one ROCm prefix holding bin/hipcc and lib/libamdhip64,
  # which nixpkgs splits across packages. rocwmma belongs here too. An
  # architecture with matrix cores, which includes every gfx11xx card, compiles
  # the WMMA paths, and backend_gpu_compat.h fails without those headers.
  rocmHome = symlinkJoin {
    name = "colibri-rocm-home";
    paths = with rocmPackages; [
      clr
      hip-common
      hipcc
      llvm.clang
      rocm-core
      rocm-device-libs
      rocwmma
    ];
  };

  # hipcc resolves device bitcode relative to its own compiler, not from
  # ROCM_PATH, so point it at the joined prefix. Wrapping keeps the Makefile's
  # own HIPCCFLAGS, which a command-line override would suppress along with the
  # per-architecture WMMA handling.
  hipccWrapped = writeShellScriptBin "hipcc" ''
    exec ${rocmHome}/bin/hipcc \
      --rocm-path=${rocmHome} \
      -I${rocmHome}/include \
      "$@"
  '';

  hipFlags = [
    "HIP=1"
    "HIP_ARCH=${hipArch}"
    "ROCM_HOME=${rocmHome}"
    "HIPCC=${lib.getExe hipccWrapped}"
  ];

  cpuFlags = [ "ARCH=${archBaseline}" ];

  # colibri probes the machine by shelling out, and a systemd unit carries a
  # minimal PATH, so each probe needs a store path.
  #
  # lscpu counts physical cores. Without it the planner counts logical CPUs and
  # sets OMP_NUM_THREADS to twice the core count. That over-subscribes SMT
  # siblings. This host measured 4.2 tokens per second at 32 threads against 7.0
  # at 16 threads.
  #
  # ldd reports whether the engine linked a GPU runtime, and rocm-smi enumerates
  # devices. Without both, --vram refuses to run even though the binary links
  # libamdhip64, so the tier stays compiled in and unused.
  probePath = [
    "${lib.getBin util-linux}/bin"
  ]
  ++ lib.optionals hipSupport [
    "${lib.getBin stdenv.cc.libc}/bin"
    "${rocmPackages.rocm-smi}/bin"
  ];

  wrapperArgs = ''--prefix PATH : "${lib.concatStringsSep ":" probePath}"'';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "colibri";
  version = "1.10.1-unstable-2026-08-31";

  src = fetchFromGitHub {
    owner = "JustVugg";
    repo = "colibri";
    rev = "12a5c464b5c1f8292d578c62458706bc32d6ac95";
    hash = "sha256-nWIp71zq0jb15+W8w5tyfmegFREgy1zgEiAcvO1d1hU=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # Upstream gates the qwen36 VRAM expert tier on CUDA alone, yet HIP=1 still
  # links the shared backend object into that engine. The tier then compiles
  # out while NOCUDA_LDFLAGS strips -lstdc++, so the C++ object cannot link and
  # the build fails on __throw_system_error. Widening the gate to accept HIP
  # fixes the link and enables the tier: qwen36_tier.c includes no vendor
  # headers and calls only the coli_cuda_* ABI that either backend provides.
  postPatch = lib.optionalString hipSupport ''
    ${lib.getExe python3} - <<'PATCH'
    import pathlib
    m = pathlib.Path("c/Makefile")
    text = m.read_text()
    old = "ifeq ($(CUDA),1)\nQWEN36_TIER_SRC = qwen36_tier.c"
    new = "ifneq (,$(filter 1,$(CUDA) $(HIP)))\nQWEN36_TIER_SRC = qwen36_tier.c"
    assert text.count(old) == 1, "qwen36 tier gate not found"
    m.write_text(text.replace(old, new))
    PATCH
  '';

  # libgomp belongs to the runtime closure because the engine is an OpenMP
  # build.
  buildInputs = [ stdenv.cc.cc.lib ];

  buildPhase = ''
        runHook preBuild
    ${lib.optionalString hipSupport ''
      # HIP reaches only the engines that link the shared backend object. It
      # still defines -DCOLI_CUDA globally, so inkling compiles GPU paths whose
      # backend_cuda_ink.o upstream never builds for AMD, and the install target
      # fails to link. Build the HIP-capable engines on their own, keep them, and
      # let the CPU pass below produce the rest.
      make -C c colibri qwen36 ${builtins.concatStringsSep " " (cpuFlags ++ hipFlags)}
      mkdir -p hip-engines
      cp c/colibri c/qwen36 hip-engines/

      # The second pass must not reuse objects compiled with -DCOLI_CUDA. The
      # clean rule runs a python helper, and the build sandbox has no
      # interpreter on PATH.
      make -C c clean PYTHON=${lib.getExe pythonEnv}
    ''}
        # The install target copies qwen36 without listing it as a prerequisite, so
        # build that engine first. Drop this once upstream fixes the rule.
        make -C c qwen36 ${builtins.concatStringsSep " " cpuFlags}

        # `make install` builds the remaining engines, then stages each beside coli
        # so its directory-relative dispatch resolves them.
        make -C c install ${builtins.concatStringsSep " " cpuFlags} \
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

    ${lib.optionalString hipSupport ''
      # Replace the CPU builds of the HIP-capable engines with the accelerated
      # ones from the first pass.
      install -m 755 hip-engines/colibri "$out/lib/colibri/colibri"
      install -m 755 hip-engines/qwen36 "$out/lib/colibri/qwen36"
    ''}
        # coli dispatches relative to its own directory, so it moves beside the
        # engines and $out/bin/coli becomes the wrapper.
        mv $out/bin/coli $out/lib/colibri/coli
        ln -s ../lib/colibri/colibri $out/bin/colibri

        # COLI_ENGINE stays unset on purpose: engine_for() routes every model to
        # the GLM engine whenever it is present, which defeats per-model dispatch.
        makeWrapper ${lib.getExe pythonEnv} $out/bin/coli \
          --add-flags "$out/lib/colibri/coli" \
          --set PYTHONPATH "$out/lib/colibri:${pythonEnv}/${python3.sitePackages}" ${wrapperArgs}

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
    description =
      "Run large mixture-of-experts models in pure C with experts streamed from disk"
      + lib.optionalString hipSupport " (HIP expert tier)";
    homepage = "https://github.com/JustVugg/colibri";
    changelog = "https://github.com/JustVugg/colibri/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "coli";
    platforms = lib.platforms.unix;
  };
})
