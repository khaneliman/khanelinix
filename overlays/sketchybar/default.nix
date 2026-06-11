_: _final: prev: {
  # Testing upstream font feature fixes:
  # - PR 826: typographical_width option so tnum actually stabilizes digit widths
  # - PR 828: use OpenType features directly, +feat/-feat syntax
  # Drop this overlay once both are merged and released.
  sketchybar = prev.sketchybar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch2 {
        name = "sketchybar-pr-826-typographical-width.patch";
        url = "https://github.com/FelixKratz/SketchyBar/pull/826.patch";
        hash = "sha256-ArshI3RmQKrNlk0SZez0+rQiuD9JFOE3ELr3MIJDP64=";
      })
      (prev.fetchpatch2 {
        name = "sketchybar-pr-828-opentype-features.patch";
        url = "https://github.com/FelixKratz/SketchyBar/pull/828.patch";
        hash = "sha256-fYO/y475fugxw82yc+8PVfwIUIWpLkJ2z8W6GFFnQ5I=";
      })
    ];
  });
}
