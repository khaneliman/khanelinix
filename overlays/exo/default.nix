_: _final: prev:
let
  mlxMetal = prev.python3Packages.buildPythonPackage {
    pname = "mlx-metal";
    version = "0.31.2";
    format = "wheel";

    src = prev.fetchurl {
      url = "https://files.pythonhosted.org/packages/99/82/11fd62a8d7a3e96e5c43220b17de0151e3f10101f8bb3b865f5bd9cdd074/mlx_metal-0.31.2-py3-none-macosx_26_0_arm64.whl";
      hash = "sha256-hP+2DuUD8D62hPX7Fo1c/zHioWt/J8FzHq92Yr1um0Y=";
    };
  };

  mlx =
    if prev.stdenv.hostPlatform.isDarwin && prev.stdenv.hostPlatform.isAarch64 then
      prev.python3Packages.buildPythonPackage {
        pname = "mlx";
        version = "0.31.2";
        format = "wheel";

        src = prev.fetchurl {
          url = "https://files.pythonhosted.org/packages/ca/20/c6c5fb998c7834d094b2bfb9f003b5246cb270f0266da055c55546c34999/mlx-0.31.2-cp313-cp313-macosx_26_0_arm64.whl";
          hash = "sha256-wFmBaEJ5qJNdWLDd4+pbAtIQw7rTMZqg6ZNOwt8WV1I=";
        };

        dependencies = [
          mlxMetal
          prev.python3Packages.numpy
        ];

        postInstall = ''
          ln -s \
            ${mlxMetal}/${prev.python3Packages.python.sitePackages}/mlx/lib \
            $out/${prev.python3Packages.python.sitePackages}/mlx/lib
        '';

        pythonImportsCheck = [ "mlx" ];
      }
    else
      prev.python3Packages.mlx;

  mlx-lm = prev.python3Packages.mlx-lm.overridePythonAttrs (old: {
    dependencies =
      builtins.filter (dependency: (dependency.pname or "") != "mlx") (old.dependencies or [ ])
      ++ [
        mlx
      ];
  });

  mlx-vlm = prev.python3Packages.mlx-vlm.overridePythonAttrs (old: {
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
  });

  mflux = prev.python3Packages.mflux.overridePythonAttrs (old: {
    dependencies =
      builtins.filter (dependency: (dependency.pname or "") != "mlx") (old.dependencies or [ ])
      ++ [
        mlx
      ];
  });
in
{
  exo = prev.exo.overridePythonAttrs (old: {
    dependencies =
      builtins.filter (
        dependency:
        !(builtins.elem (dependency.pname or "") [
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
        prev.python3Packages.torchvision
      ];
  });
}
