{ stdenv, pkgs, ... }:
# TODO: upstream
stdenv.mkDerivation rec {
  name = "artifacts-credprovider";
  version = "1.3.0";

  src = pkgs.fetchurl {
    url = "https://github.com/microsoft/artifacts-credprovider/releases/download/v${version}/Microsoft.Net8.NuGet.CredentialProvider.tar.gz";
    hash = "sha256-WEssfdOKMjJ3WD/egD4wA69k+JdB9O/ZWM8RstRJGkA=";
  };

  buildPhase = ''
    mkdir -p $out/bin
    cp -r netcore $out/bin
  '';
}
