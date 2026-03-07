_: _final: prev: {
  jankyborders = prev.jankyborders.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch2 {
        name = "ignore-windows-that-ignore-window-cycling";
        url = "https://github.com/FelixKratz/JankyBorders/commit/93577ca1f2210f7c5f85775909822cad59b6327f.patch?full_index=1";
        hash = "sha256-zqX2C/Ps76VFGCnmQr+dzfeVqE9hiBoPa+grfeekoDk=";
      })
    ];
  });
}
