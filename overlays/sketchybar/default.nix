_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # Deferred resize callbacks must not retain embedded popup/bar windows.
      # Remove when upstream fixes the 2.24.0 window lifetime regression.
      ./sketchybar-2.24.0-deferred-surface-lifetime.patch
    ];
  });
}
