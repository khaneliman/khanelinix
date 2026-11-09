_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # Deferred resize callbacks must not retain embedded popup/bar windows.
      # Backport of FelixKratz/SketchyBar#875 (26723d1); remove once nixpkgs
      # ships a release newer than 2.24.1.
      ./sketchybar-2.24.0-deferred-surface-lifetime.patch
    ];
  });
}
