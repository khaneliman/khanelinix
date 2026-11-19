{ lib, ... }:
{
  imports = [ ../../common/home ];

  config.environment.pathsToLink = lib.mkAfter [ "/share/applications" ];
}
