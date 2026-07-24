# nixpkgs versions gguf by llama.cpp build tag (9967) while gguf-py's pyproject
# still declares 0.19.0, so pythonMetadataCheckPhase fails. Patch the project
# version to match, as the hook error message recommends.
_: _final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      gguf = pythonPrev.gguf.overridePythonAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          pythonPrev.pyprojectVersionPatchHook
        ];
      });
    })
  ];
}
