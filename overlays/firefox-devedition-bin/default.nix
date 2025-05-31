_: _final: prev: {
  # FIXME: Upstream broken after https://github.com/NixOS/nixpkgs/pull/410404
  firefox-devedition-bin-unwrapped = prev.firefox-devedition-bin-unwrapped.overrideAttrs (_oldAttrs: {
    dontFixup = false;
  });
}
