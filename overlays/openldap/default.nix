_: _final: prev: {
  # https://github.com/NixOS/nixpkgs/issues/513245
  openldap = prev.openldap.overrideAttrs {
    doCheck = !prev.stdenv.hostPlatform.isi686;
  };
  pkgsi686Linux = prev.pkgsi686Linux // {
    openldap = prev.pkgsi686Linux.openldap.overrideAttrs (_: {
      doCheck = false;
    });
  };
}
