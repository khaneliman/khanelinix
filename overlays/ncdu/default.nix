{ ...
}: _final: prev: {
  # FIX: resolve nixpkgs broken build
  ncdu = prev.ncdu.overrideAttrs (_oldAttrs: {
    zigBuildFlags = prev.lib.optional prev.stdenv.isDarwin "-Dpie=true";
  });
}
