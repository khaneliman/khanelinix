_: _final: prev: {
  # Testing upstream font feature fixes:
  # - PR 826: typographical_width option so tnum actually stabilizes digit widths
  # - PR 828: use OpenType features directly, +feat/-feat syntax
  # Drop this overlay once both are merged and released.
  sketchybar = prev.sketchybar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch2 {
        name = "sketchybar-pr-826-typographical-width.patch";
        url = "https://github.com/FelixKratz/SketchyBar/commit/fc2cdcfabf764c5f7d8695ee7573a8f26c8bbe89.patch";
        hash = "sha256-ArshI3RmQKrNlk0SZez0+rQiuD9JFOE3ELr3MIJDP64=";
      })
      (prev.fetchpatch2 {
        name = "sketchybar-pr-828-opentype-features.patch";
        url = "https://github.com/FelixKratz/SketchyBar/commit/84a6ad36089070c8b3b07d7885375f177d72e951.patch";
        hash = "sha256-AVZvDJUYk5x77639kPZH437Zj8ff6gee0OWHx1YfE7A=";
      })
    ];
  });
}
