{ inputs }:
final: _prev: {
  # Add our extended khanelinix functions to lib
  khanelinix = import ./module { inherit inputs; };

  file = import ./file {
    inherit inputs;
    self = ../.;
  };
  inherit (final.file) getFile importModulesRecursive;

  # System configuration builders
  system = import ./system { inherit inputs; };

  # Also add individual namespaces for convenience
  inherit (final.khanelinix)
    mkOpt
    mkOpt'
    mkBoolOpt
    mkBoolOpt'
    enabled
    disabled
    ;
  inherit (final.khanelinix) capitalize boolToNum;
  inherit (final.khanelinix)
    default-attrs
    force-attrs
    nested-default-attrs
    nested-force-attrs
    decode
    ;

  # Add home-manager lib functions
  inherit (inputs.home-manager.lib) hm;
}
