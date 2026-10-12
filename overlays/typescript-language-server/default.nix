_: _final: prev: {
  typescript-language-server = prev.typescript-language-server.overrideAttrs (
    old:
    prev.lib.optionalAttrs (old.version == "6.0.2") {
      # The dependency hash in nixpkgs does not match pnpm 12.9's store.
      pnpmDeps = old.pnpmDeps.overrideAttrs {
        outputHash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
      };
    }
  );
}
