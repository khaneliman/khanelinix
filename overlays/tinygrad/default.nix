# nixpkgs already skips tinygrad's flaky performance tests, but not this one. It
# asserts a wall-clock deadline (20s) that a loaded builder blows past, so it
# fails whenever other derivations build alongside it.
_: _final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      tinygrad = pythonPrev.tinygrad.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [
          # DeadlineExceeded('Test took 25951.43ms, which exceeds the deadline
          # of 20000.00ms.')
          "test_approx_jit_timeout"
        ];
      });
    })
  ];
}
