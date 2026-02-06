{ inputs }:
_final: _prev:
let
  # Import each lib module directly instead of re-evaluating the flake-parts module
  base64Lib = import ./base64 { inherit inputs; };
  fileLib = import ./file {
    inherit inputs;
    self = ../.;
  };
  moduleLib = import ./module { inherit inputs; };
  systemLib = import ./system { inherit inputs; };
  themeLib = import ./theme { inherit inputs; };
in
{
  # Expose khanelinix module functions directly
  khanelinix = moduleLib // {
    theme = themeLib;
  };

  # Expose all khanelinix lib namespaces
  file = fileLib;
  system = systemLib;
  theme = themeLib;
  base64 = base64Lib;

  inherit (fileLib)
    getFile
    getNixFiles
    importFiles
    importDir
    importDirPlain
    importSubdirs
    importModulesRecursive
    mergeAttrs
    ;

  inherit (moduleLib)
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
