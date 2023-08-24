{ ... }: _final: prev: {
  waybar = prev.waybar.overrideAttrs (oldAttrs: {
    mesonFlags = oldAttrs.mesonFlags ++ [ (prev.lib.mesonBool "experimental" true) ];
  });
}
