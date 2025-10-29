_: _final: prev: {
  # FIXME: broken nixpkgs darwin
  jujutsu = prev.jujutsu.override {
    rustPlatform =
      prev.rustPlatform
      // prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
        buildRustPackage = prev.rustPlatform.buildRustPackage.override { cargoNextestHook = null; };
      };
  };
}
