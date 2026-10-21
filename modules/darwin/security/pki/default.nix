{ lib, pkgs, ... }:
{
  # Distrust the roots behind the compromised eMudhra intermediates until
  # nix-darwin ships it: https://github.com/nix-darwin/nix-darwin/pull/1876
  # cacert 3.131.1 drops the emSign roots, and the bundle build fails on
  # blacklist names it cannot find, so list those only for older bundles.
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
  ]
  ++ lib.optionals (lib.versionOlder pkgs.cacert.version "3.131.1") [
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];
}
