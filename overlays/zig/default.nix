_: _final: prev: {
  zig_0_12 = prev.zig_0_12.overrideAttrs (_oldAttrs: {
    preConfigure = ''
      CC=$(type -p $CC)
      CXX=$(type -p $CXX)
      LD=$(type -p $LD)
      AR=$(type -p $AR)
    '';
  });
}
