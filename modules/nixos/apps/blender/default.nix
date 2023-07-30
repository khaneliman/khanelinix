{ lib, ... }:
with lib;
with lib.internal; {
  imports = [ ../../../shared/apps/blender/default.nix ];
}
