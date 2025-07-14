{ inputs }:
final: _prev: {
  # Add our extended khanelinix functions to lib
  khanelinix = import ./module { inherit inputs; };

  # Add file utilities
  file = import ./file { inherit inputs; self = ../.; };

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

  # Add file utilities to root lib for easy access
  inherit (final.file) getFile importModulesRecursive;

  # Add home-manager lib functions
  inherit (inputs.home-manager.lib) hm;
}
