{ stdenv, pkgs, ... }:
# TODO: upstream
stdenv.mkDerivation rec {
  name = "artifacts-credprovider";
  version = "2.0.4";

  src = pkgs.fetchurl {
    url = "https://github.com/microsoft/artifacts-credprovider/releases/download/v${version}/Microsoft.Net8.NuGet.CredentialProvider.tar.gz";
    hash = "sha256-yvDQQIfy/LAzD1rxNhBChJ3l18SGt8oV+LLiF/PDhwY=";
  };

  buildPhase = ''
    mkdir -p $out/bin
    cp -r netcore $out/bin
  '';
}
