# The i686 test binaries segfault on exit when CMake runs them for test
# discovery, which fails the build. Hydra does not cache this variant, and
# Bottles' 32-bit FHS environment needs it through graphicsmagick and libjxl.
_: _final: prev: {
  libhwy = prev.libhwy.overrideAttrs (
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isi686 { doCheck = false; }
  );
}
