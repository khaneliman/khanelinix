{ inputs }:
let

  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    mkOption
    types
    toUpper
    mkDefault
    mkForce
    ;

  base64Lib = import ../base64 { inherit inputs; };
in
rec {
  # Original flake-parts module utilities
  # Enable a module with optional configuration
  enable =
    module: config:
    {
      imports = [ module ];
    }
    // config;

  # Conditionally enable modules based on system
  enableForSystem =
    system: modules:
    builtins.filter (
      mod: mod.systems or [ ] == [ ] || builtins.elem system (mod.systems or [ ])
    ) modules;

  # Create a module with common options
  mkModule =
    {
      name,
      description ? "",
      options ? { },
      config ? { },
    }:
    { lib, ... }:
    {
      options.khanelinix.${name} = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption description;
          }
          // options;
        };
        default = { };
      };

      config = lib.mkIf config.khanelinix.${name}.enable config;
    };

  # Migrated khanelinix utilities
  # Option creation helpers
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  mkOpt' = type: default: mkOpt type default null;

  mkBoolOpt = mkOpt types.bool;

  mkBoolOpt' = mkOpt' types.bool;

  # Standard enable/disable patterns
  enabled = {
    enable = true;
  };

  disabled = {
    enable = false;
  };

  # String utilities
  capitalize =
    s:
    let
      len = lib.stringLength s;
    in
    if len == 0 then "" else (toUpper (lib.substring 0 1 s)) + (lib.substring 1 len s);

  # Boolean utilities
  boolToNum = bool: if bool then 1 else 0;

  # Attribute manipulation utilities
  default-attrs = lib.mapAttrs (_key: mkDefault);

  force-attrs = lib.mapAttrs (_key: mkForce);

  nested-default-attrs = lib.mapAttrs (_key: default-attrs);
  nested-force-attrs = lib.mapAttrs (_key: force-attrs);
}
// base64Lib
