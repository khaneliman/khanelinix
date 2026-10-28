_: final: prev:
let
  # MLX only ships a CPython 3.13 Darwin wheel, so exo and its whole MLX stack
  # must be built against python313Packages. Loading the wheel through the
  # default 3.14 interpreter leaves mlx.core without its compiled attributes.
  pythonPackages =
    if prev.stdenv.hostPlatform.isDarwin then final.python313Packages else final.python3Packages;

  useMetalWheel = prev.stdenv.hostPlatform.isDarwin && prev.stdenv.hostPlatform.isAarch64;

  # The MLX wheels are Metal-enabled builds, so importing them needs a real GPU.
  # The sandbox has none — nixpkgs builds its own MLX with MLX_BUILD_METAL=false
  # for that reason, which also costs it GPU acceleration at runtime. Skip the
  # execution-based checks instead of relaxing the sandbox; the wheels only run
  # at runtime, where Metal is available.
  #
  # Skip those phases individually rather than setting doCheck = false: some of
  # these packages declare runtime dependencies that nixpkgs supplies only as
  # nativeCheckInputs (mlx-lm needs sentencepiece), so dropping the check inputs
  # makes pythonRuntimeDepsCheck fail instead.
  withoutGpuChecks =
    package:
    if useMetalWheel then
      package.overridePythonAttrs {
        dontUsePythonImportsCheck = true;
        dontUsePytestCheck = true;
      }
    else
      package;

  mlxMetal = pythonPackages.buildPythonPackage {
    pname = "mlx-metal";
    version = "0.32.4";
    format = "wheel";

    src = prev.fetchurl {
      url = "https://files.pythonhosted.org/packages/2a/d6/4340ed6e184f71693d7f531c9ae55d677451351245760d71f8dd714dcbe5/mlx_metal-0.32.4-py3-none-macosx_26_0_arm64.whl";
      hash = "sha256-UU35LUGiholdJWS0sY9NpFCWvXpKDEfhBC80WtWn+TY=";
    };
  };

  mlx =
    if useMetalWheel then
      pythonPackages.buildPythonPackage {
        pname = "mlx";
        version = "0.32.4";
        format = "wheel";

        src = prev.fetchurl {
          url = "https://files.pythonhosted.org/packages/e8/b1/33ca08f84550fd512f28b84055ff00631ef2ce83011ac2bbc171ffec7bbb/mlx-0.32.4-cp313-cp313-macosx_26_0_arm64.whl";
          hash = "sha256-7xMOPaiVyFN0sRpsOJrLEiiT8v/L7YJri2L9RaILetY=";
        };

        dependencies = [
          mlxMetal
          pythonPackages.numpy
        ];

        postInstall = ''
          ln -s \
            ${mlxMetal}/${pythonPackages.python.sitePackages}/mlx/lib \
            $out/${pythonPackages.python.sitePackages}/mlx/lib
        '';

        pythonImportsCheck = [ "mlx" ];
      }
    else
      pythonPackages.mlx;

  mlx-lm = withoutGpuChecks (
    pythonPackages.mlx-lm.overridePythonAttrs (old: {
      dependencies =
        builtins.filter (dependency: (dependency.pname or "") != "mlx") (old.dependencies or [ ])
        ++ [
          mlx
        ];
    })
  );

  mlx-vlm = withoutGpuChecks (
    pythonPackages.mlx-vlm.overridePythonAttrs (old: {
      dependencies =
        builtins.filter (
          dependency:
          !(builtins.elem (dependency.pname or "") [
            "mlx"
            "mlx-lm"
          ])
        ) (old.dependencies or [ ])
        ++ [
          mlx
          mlx-lm
        ];

      # nixpkgs marks mlx-vlm 0.4.4 broken. It declares mlx>=0.30.0 and imports
      # cleanly against the Metal wheel above on real hardware.
      meta = (old.meta or { }) // prev.lib.optionalAttrs useMetalWheel { broken = false; };
    })
  );

  mflux = withoutGpuChecks (
    pythonPackages.mflux.overridePythonAttrs (old: {
      dependencies =
        builtins.filter (dependency: (dependency.pname or "") != "mlx") (old.dependencies or [ ])
        ++ [
          mlx
        ];
    })
  );

  basePackage =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.exo.override { python3Packages = pythonPackages; }
    else
      prev.exo;

  pyo3-bindings = basePackage.exo-pyo3-bindings;
in
{
  # exo imports the MLX stack, so it inherits the same sandbox GPU limitation.
  exo = withoutGpuChecks (
    basePackage.overridePythonAttrs (old: {
      # exo tags releases without bumping pyproject's version, so patch it to the
      # derivation version for pythonMetadataCheckPhase.
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        pythonPackages.pyprojectVersionPatchHook
      ];

      passthru = (old.passthru or { }) // {
        exo-pyo3-bindings = pyo3-bindings;
        # Consumers such as the Application Firewall allowlist need the exact
        # interpreter exo runs under, which this overlay pins per platform.
        inherit (pythonPackages) python;
      };

      dependencies =
        builtins.filter (
          dependency:
          !(builtins.elem (dependency.pname or "") [
            "exo-pyo3-bindings"
            "mflux"
            "mlx"
            "mlx-lm"
            "mlx-vlm"
          ])
        ) (old.dependencies or [ ])
        ++ [
          mflux
          mlx
          mlx-lm
          mlx-vlm
          pyo3-bindings
          pythonPackages.torchvision
        ];
    })
  );
}
