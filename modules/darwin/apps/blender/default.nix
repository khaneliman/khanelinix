{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.blender;
in {
  imports = [../../../shared/apps/blender/default.nix];
}
