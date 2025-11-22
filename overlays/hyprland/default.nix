_: _final: prev: {
  hyprland = prev.hyprland.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (prev.fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/hyprwm/Hyprland/pull/12090.patch";
        hash = "sha256-pUtFyhiLku4OBXlDI/FgBo8QkG3XbCF1RWdXUXkylLY=";
      })
    ];
  });
}
