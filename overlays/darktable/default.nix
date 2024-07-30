_: _final: prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/331096 in unstable
  darktable = prev.darktable.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [
      prev.libyuv
      prev.dav1d
    ];
  });
}
