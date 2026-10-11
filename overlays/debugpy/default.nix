_: final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (
      _pythonFinal: pythonPrev:
      prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
        debugpy = pythonPrev.debugpy.overridePythonAttrs (old: {
          # Remove once nixpkgs updates this test for its hardcoded LLDB path.
          postPatch = (old.postPatch or "") + ''
            substituteInPlace tests/debugpy/server/test_add_code_to_python_process.py \
              --replace-fail '"lldb --no-lldbinit --script-language Python "' \
                '"${prev.lib.getExe' final.lldb "lldb"} --no-lldbinit --script-language Python "'
          '';
        });
      }
    )
  ];
}
