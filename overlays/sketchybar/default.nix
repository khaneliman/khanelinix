# audit-package: sketchybar darwin
# audit-review: Check whether the locked source contains the deferred-resize fix before dropping the backport.
_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # Deferred resize callbacks must not retain embedded popup/bar windows.
      # Backport of https://github.com/FelixKratz/SketchyBar/pull/875 (26723d1).
      ./sketchybar-2.24.0-deferred-surface-lifetime.patch
    ];
  });
}
