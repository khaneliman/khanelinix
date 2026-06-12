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
  /**
    Enable a module with optional configuration.

    # Inputs

    `module`

    : 1\. Function argument

    `config`

    : 2\. Function argument
  */
  enable =
    module: config:
    {
      imports = [ module ];
    }
    // config;

  /**
    Conditionally enable modules based on system.

    # Inputs

    `system`

    : 1\. Function argument

    `modules`

    : 2\. Function argument
  */
  enableForSystem =
    system: modules:
    builtins.filter (
      mod: mod.systems or [ ] == [ ] || builtins.elem system (mod.systems or [ ])
    ) modules;

  # Migrated khanelinix utilities
  # Option creation helpers

  /**
    Create a nixpkgs option.

    # Inputs

    `type`

    : 1\. Function argument

    `default`

    : 2\. Function argument

    `description`

    : 3\. Function argument
  */
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  /**
    Create a nixpkgs option without a description.

    # Inputs

    `type`

    : 1\. Function argument

    `default`

    : 2\. Function argument
  */
  mkOpt' = type: default: mkOpt type default null;

  /**
    Create a boolean nixpkgs option.

    # Inputs

    `type`

    : 1\. Function argument

    `default`

    : 2\. Function argument

    `description`

    : 3\. Function argument
  */
  mkBoolOpt = mkOpt types.bool;

  /**
    Create a boolean nixpkgs option without a description.

    # Inputs

    `type`

    : 1\. Function argument

    `default`

    : 2\. Function argument
  */
  mkBoolOpt' = mkOpt' types.bool;

  /**
    Standard enabled pattern.
  */
  enabled = {
    enable = true;
  };

  /**
    Standard disabled pattern.
  */
  disabled = {
    enable = false;
  };

  /**
    Capitalize a string.

    # Inputs

    `s`

    : 1\. Function argument
  */
  capitalize =
    s:
    let
      len = lib.stringLength s;
    in
    if len == 0 then "" else (toUpper (lib.substring 0 1 s)) + (lib.substring 1 len s);

  /**
    Convert a boolean to a number.

    # Inputs

    `bool`

    : 1\. Function argument
  */
  boolToNum = bool: if bool then 1 else 0;

  /**
    Package profile tiers, from smallest to broadest payload.
  */
  packageProfiles = [
    "core"
    "standard"
    "maximal"
  ];

  /**
    Package profile option type.
  */
  packageProfileType = types.enum packageProfiles;

  /**
    Package profile ranks for inclusion checks.
  */
  packageProfileRank = {
    core = 0;
    standard = 1;
    maximal = 2;
  };

  /**
    Whether an active package profile includes a tier.
  */
  profileIncludes = active: tier: packageProfileRank.${active} >= packageProfileRank.${tier};

  /**
    Standard suite package profile override option.
  */
  mkPackageProfileOption = description: mkOpt (types.nullOr packageProfileType) null description;

  /**
    Resolve a package profile override against a global default.
  */
  resolvePackageProfile = global: override: if override == null then global else override;

  /**
    Resolve a suite package profile from module config and suite config.
  */
  suitePackageProfile =
    config: suiteCfg: resolvePackageProfile config.khanelinix.packageProfile suiteCfg.packageProfile;

  /**
    Whether a suite's effective package profile includes a tier.
  */
  suiteProfileIncludes = config: suiteCfg: profileIncludes (suitePackageProfile config suiteCfg);

  /**
    Apply mkDefault to all attributes in a set.

    # Inputs

    `set`

    : 1\. Function argument
  */
  default-attrs = lib.mapAttrs (_key: mkDefault);

  /**
    Apply mkForce to all attributes in a set.

    # Inputs

    `set`

    : 1\. Function argument
  */
  force-attrs = lib.mapAttrs (_key: mkForce);

  /**
    Apply default-attrs to nested attribute sets.

    # Inputs

    `set`

    : 1\. Function argument
  */
  nested-default-attrs = lib.mapAttrs (_key: default-attrs);

  /**
    Apply force-attrs to nested attribute sets.

    # Inputs

    `set`

    : 1\. Function argument
  */
  nested-force-attrs = lib.mapAttrs (_key: force-attrs);
}
// base64Lib
