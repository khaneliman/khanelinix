_: _final: prev: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/353338 is available
  neatvnc = prev.neatvnc.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [ ] ++ [ ./fix-ffmpeg.patch ];
  });
}
