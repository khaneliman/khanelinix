_: _final: prev: {
  zig_0_12 = prev.zig_0_12.overrideAttrs (_oldAttrs: {
    strictDeps = !prev.stdenv.cc.isClang;
  });
}
