{
  self,
  lib,
  ...
}:
{
  flake.lib = {
    khanelinix = lib.makeOverridable (import ../../lib) {
      inherit lib;
      flake = self;
    };
  };
}
