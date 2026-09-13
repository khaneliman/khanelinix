# nixpkgs already skips tinygrad's flaky performance tests, but not these. The
# wall-clock ones assert a deadline (20s) that a loaded builder blows past, so
# they fail whenever other derivations build alongside them.
_: _final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      tinygrad = pythonPrev.tinygrad.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [
          # DeadlineExceeded('Test took 25951.43ms, which exceeds the deadline
          # of 20000.00ms.')
          "test_approx_jit_timeout"
          # AssertionError: 15.95… not less than 9.0 : should exit in time
          # (test/amd/test_mockgpu_invalid.py, same wall-clock class)
          "test_unsupported_instruction_raises"
          # Deterministic, not flaky: torch 2.13 saturates out-of-range floats
          # to FP8 e4m3 max (0x7e) while tinygrad 0.13.0 still returns NaN
          # (0x7f). Drop once tinygrad matches torch's saturating conversion.
          "test_float_to_fp8e4m3_extreme_values"
        ];
      });
    })
  ];
}
