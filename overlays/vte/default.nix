_: _final: prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/353204 is available
  vte = prev.vte.overrideAttrs (oldAttrs: rec {
    version = "0.78.1";
    src = prev.fetchFromGitLab {
      domain = "gitlab.gnome.org";
      owner = "GNOME";
      repo = "vte";
      rev = version;
      hash = "sha256-dVCvf4eTIJlrSzG6xLdKU47N9uAtHDwRrGkWtSmqbEU=";
    };
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ prev.fast-float ];
    patches = oldAttrs.patches or [ ] ++ [
      # build: Add fast_float dependency
      # https://gitlab.gnome.org/GNOME/vte/-/issues/2823
      (prev.fetchpatch {
        name = "0003-build-Add-fast_float-dependency.patch";
        url = "https://gitlab.gnome.org/GNOME/vte/-/commit/f6095fca4d1baf950817e7010e6f1e7c313b9e2e.patch";
        hash = "sha256-EL9PPiI5pDJOXf4Ck4nkRte/jHx/QWbxkjDFRSsp+so=";
      })
      (prev.fetchpatch {
        name = "0003-widget-termprops-Use-fast_float.patch";
        url = "https://gitlab.gnome.org/GNOME/vte/-/commit/6c2761f51a0400772f443f12ea23a75576e195d3.patch";
        hash = "sha256-jjM9bhl8EhtylUIQ2nMSNX3ugnkZQP/2POvSUDW0LM0=";
      })
      (prev.fetchpatch {
        name = "0003-build-Use-correct-path-to-include-fast_float.h.patch";
        url = "https://gitlab.gnome.org/GNOME/vte/-/commit/d09330585e648b5c9991dffab4a06d1f127bf916.patch";
        hash = "sha256-YGVXt2VojljYgTcmahQ2YEZGEysyUSwk+snQfoipJ+E=";
      })
    ];
  });
}
