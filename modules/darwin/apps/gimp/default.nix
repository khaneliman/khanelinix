{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.gimp;
in {
  imports = [../../../shared/apps/gimp/default.nix];
}
