_: _final: prev: {
  # TODO: remove after hits channel
  # https://github.com/NixOS/nixpkgs/pull/449689
  gtk3 = prev.gtk3.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [ ])
      ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
        ./sincos.patch
      ];
  });
}
