{ stdenv, pkgs, ... }:
# TODO: upstream
stdenv.mkDerivation rec {
  name = "artifacts-credprovider";
  version = "2.0.5";

  src = pkgs.fetchurl {
    url = "https://github.com/microsoft/artifacts-credprovider/releases/download/v${version}/Microsoft.Net8.NuGet.CredentialProvider.tar.gz";
    hash = "sha256-LP6ZUt/MfhJ4jzQ8QTObfV7/GdSOEmeYBbIh/KldE4k=";
  };

  buildPhase = ''
    mkdir -p $out/bin
    cp -r netcore $out/bin
  '';
}
