{ lib, self, ... }:
{
  # Create internal lib
  flake.lib = {
    khanelinix = lib.makeOverridable (import ../lib) {
      inherit lib self;
      root = ../.;
    };
  };

  # Expose lib as a flake-parts module arg
  _module.args = {
    khanelinix-lib = self.lib.khanelinix;
    namespace = "khanelinix";
    # Make sure the extended lib is available too
    lib = lib.extend (
      _final: _prev: {
        inherit (self.lib) khanelinix;
      }
    );
  };
}
