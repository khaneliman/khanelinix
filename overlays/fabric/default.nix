# Fabric 3.2.3 does not support Invoke 3, so nixpkgs marks it broken and
# azure-cli stops evaluating (https://github.com/NixOS/nixpkgs/issues/575989).
# Upstream fixed this only on the unreleased 4.x branch; backport that commit
# until nixpkgs ships a compatible Fabric.
_: _final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      fabric = pythonPrev.fabric.overridePythonAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch2 {
            name = "fabric-invoke-3.patch";
            url = "https://github.com/fabric/fabric/commit/7fa309db9dd5dac69079c1fb83b6f579555f7d53.patch";
            hash = "sha256-93Oz/LM4LiIPGNdvN5EdJkMQpysUU8ddaRcTsdysBDU=";
          })
        ];

        pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "invoke" ];

        # The tests load the hardcoded system /etc/ssh/ssh_config. Darwin
        # builds run unsandboxed here, where that file is root-only, so
        # every Connection fixture fails. Linux builds stay sandboxed.
        doCheck = !prev.stdenv.hostPlatform.isDarwin;

        meta = old.meta // {
          broken = false;
        };
      });
    })
  ];
}
