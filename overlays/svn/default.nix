_: _final: prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/341232 is available
  subversionClient = prev.subversionClient.overrideAttrs (_oldAttrs: {
    env = prev.lib.optionalAttrs prev.stdenv.cc.isClang {
      NIX_CFLAGS_COMPILE = toString [
        "-Wno-error=implicit-function-declaration"
        "-Wno-error=implicit-int"
        "-Wno-int-conversion"
      ];
    };
  });
}
