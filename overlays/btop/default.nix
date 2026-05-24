_: _final: prev: {
  btop = prev.btop.overrideAttrs (old: {
    patches =
      (old.patches or [ ])
      ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
        (prev.fetchpatch2 {
          name = "btop-pr-1662-darwin-runner-stall-fix.patch";
          url = "https://github.com/aristocratos/btop/pull/1662.patch";
          hash = "sha256-9mgi5yAqm4PGexzYh74PmTBjD+ygXO13YFcSJKDlVc4=";
        })
      ];
  });
}
