_: _final: prev: {
  # TODO: remove after hits channel
  gtk3 = prev.gtk3.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [ ])
      ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
        ./sincos.patch
      ];
  });
}
