{ inputs }:
_final: _prev:
let
  khanelinixLib = import ./default.nix { inherit inputs; };
in
{
  # Expose khanelinix module functions directly
  khanelinix = khanelinixLib.flake.lib.module // {
    inherit (khanelinixLib.flake.lib) theme;
  };

  # Expose all khanelinix lib namespaces
  inherit (khanelinixLib.flake.lib)
    file
    system
    theme
    base64
    ;

  inherit (khanelinixLib.flake.lib.file)
    getFile
    getNixFiles
    importFiles
    importDir
    importDirPlain
    importSubdirs
    importModulesRecursive
    mergeAttrs
    ;

  inherit (khanelinixLib.flake.lib.module)
    mkOpt
    mkOpt'
    mkBoolOpt
    mkBoolOpt'
    enabled
    disabled
    capitalize
    boolToNum
    default-attrs
    force-attrs
    nested-default-attrs
    nested-force-attrs
    decode
    ;

  # Add home-manager lib functions
  inherit (inputs.home-manager.lib) hm;
}
