# nixpkgs already skips tinygrad's flaky performance tests, but this test
# checks wall-clock exit time and can fail on a loaded builder.
_: _final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      tinygrad = pythonPrev.tinygrad.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [
          # AssertionError: 15.95… not less than 9.0 : should exit in time
          # (test/amd/test_mockgpu_invalid.py, same wall-clock class)
          "test_unsupported_instruction_raises"
          # torch 2.14 changed the reference results these compare against:
          # clip's backward shape and replicate-mode padding bounds.
          "test_clip"
          "test_pad_replicate_mode"
        ];
      });
    })
  ];
}
