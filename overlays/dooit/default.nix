_: _final: prev: {
  # TODO: remove once fix makes it to nixos-unstable
  dooit = prev.dooit.overridePythonAttrs (oldAttrs: {
    pyproject = true;
    format = null;

    nativeBuildInputs = with prev.python3.pkgs; [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "tzlocal"
    ];
  });
}
