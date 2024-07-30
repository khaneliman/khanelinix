_: _final: prev: {
  # TODO: remove override after https://github.com/NixOS/nixpkgs/pull/331120 is in unstable
  snapper = prev.snapper.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ prev.zlib ];
  });
}
