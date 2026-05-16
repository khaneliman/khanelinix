_: _final: prev: {
  exo = prev.exo.overridePythonAttrs (old: {
    dependencies = (old.dependencies or [ ]) ++ [
      prev.python3Packages.torchvision
    ];
  });
}
