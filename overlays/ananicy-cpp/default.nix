_: _final: prev: {
  ananicy-cpp = prev.ananicy-cpp.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./missing-standard-headers.patch ];
  });
}
