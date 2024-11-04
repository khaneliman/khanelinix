{
  useUasm ? false,
  ...
}:
# TODO: remove after https://github.com/NixOS/nixpkgs/pull/353272 is available
_final: prev: {
  _7zz = prev._7zz.overrideAttrs (oldAttrs: {
    makeFlags =
      oldAttrs.makeFlags
      ++ prev.lib.optionals (!useUasm && prev.stdenv.hostPlatform.isx86) [ "USE_ASM=" ];
  });
}
