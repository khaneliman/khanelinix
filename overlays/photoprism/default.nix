_: final: prev: {
  # tensorflow-bin does not support the default Python 3.14 yet.
  photoprism = prev.photoprism.override {
    callPackage =
      path: args:
      prev.callPackage path (
        args
        // prev.lib.optionalAttrs (baseNameOf path == "backend.nix") {
          python3 = final.python313;
        }
      );
  };
}
