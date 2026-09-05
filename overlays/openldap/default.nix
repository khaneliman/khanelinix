_: _final: prev: {
  # https://github.com/NixOS/nixpkgs/issues/426717 (closed, not planned)
  openldap = prev.openldap.overrideAttrs {
    doCheck = !prev.stdenv.hostPlatform.isi686;
  };
  pkgsi686Linux = prev.pkgsi686Linux // {
    openldap = prev.pkgsi686Linux.openldap.overrideAttrs (_: {
      doCheck = false;
    });
  };
}
