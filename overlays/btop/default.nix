_: _final: prev: {
  btop = prev.btop.overrideAttrs (old: {
    patches =
      (old.patches or [ ])
      ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
        ./btop-1.4.7-darwin-runner-stall-fix.patch
      ];
  });
}
