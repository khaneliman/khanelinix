_: _final: prev: {
  libgphoto2 = prev.libgphoto2.overrideAttrs (old: {
    patches =
      (old.patches or [ ])
      ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
        ./libgphoto2-2.5.34-darwin-libintl.patch
      ];
  });
}
