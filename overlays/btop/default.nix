_: _final: prev: {
  # TODO: remove stdenv and buildinputs override after next unstable
  btop = (prev.btop.override { inherit (prev) stdenv; }).overrideAttrs (_oldAttrs: {
    buildInputs = prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
      prev.apple-sdk_15
      (prev.darwinMinVersionHook "10.15")
    ];
  });
}
