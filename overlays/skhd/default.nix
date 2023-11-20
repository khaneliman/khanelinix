_: (_self: super: {
  skhd = super.skhd.overrideAttrs (_old: {
    env.NIX_CFLAGS_COMPILE = "-Wno-error=implicit-function-declaration";
  });
})
