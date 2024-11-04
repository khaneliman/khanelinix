_: _final: prev: {
  # TODO: remove stdenv and buildinputs override after next unstable
  fastfetch = (prev.fastfetch.override { inherit (prev) stdenv; }).overrideAttrs (oldAttrs: {
    buildInputs =
      oldAttrs.buildInputs
      ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [ prev.apple-sdk_15 ];
  });
}
