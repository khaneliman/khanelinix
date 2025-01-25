{ lib, self, ... }:
{
  # Expose lib as a flake-parts module arg
  _module.args = {
    khanelinix-lib = self.lib.khanelinix;
  };

  # Create internal lib
  flake.lib = {
    khanelinix = lib.makeOverridable (import ../lib) {
      inherit lib self;
      root = ../.;
    };
  };
}
