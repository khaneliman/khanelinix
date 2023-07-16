{lib, ...}:
with lib;
with lib.internal; {
  imports = [../../../shared/apps/gimp/default.nix];
}
