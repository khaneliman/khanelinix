{ inputs }:
let
  inherit (inputs.nixpkgs.lib)
    filterAttrs
    hasSuffix
    mapAttrs'
    optionalAttrs
    ;

  patchesRoot = ../../patches;

  mkInputPatches =
    inputName:
    let
      patchDir = patchesRoot + "/${inputName}";
    in
    if builtins.pathExists patchDir then
      map (patchName: patchDir + "/${patchName}") (
        builtins.filter (patchName: hasSuffix ".patch" patchName) (
          builtins.attrNames (builtins.readDir patchDir)
        )
      )
    else
      [ ];

  normalizeExtraInputPatches =
    pkgs: patches:
    let
      # Accept direct patch paths/derivations, `pkgs: [ ... ]`, or fetchpatch2
      # specs with url/hash. Set `fetcher = "fetchpatch"` to override.
      patchList = if builtins.isFunction patches then patches pkgs else patches;
      mkPatch =
        patch:
        if builtins.isAttrs patch && patch ? url then
          let
            fetcher = patch.fetcher or "fetchpatch2";
            fetchPatch = if builtins.isString fetcher then pkgs.${fetcher} else fetcher;
          in
          fetchPatch (removeAttrs patch [ "fetcher" ])
        else
          patch;
    in
    map mkPatch patchList;

  mkExtraInputPatches =
    {
      pkgs,
      inputName,
      extraInputPatches ? { },
    }:
    let
      patchFile = patchesRoot + "/${inputName}/default.nix";
      filePatches =
        if builtins.pathExists patchFile then
          import patchFile {
            inherit pkgs;
            inherit (pkgs) lib;
          }
        else
          [ ];
      configuredPatches = extraInputPatches.${inputName} or [ ];
    in
    normalizeExtraInputPatches pkgs filePatches ++ normalizeExtraInputPatches pkgs configuredPatches;

  mkInputPatchList =
    {
      pkgs,
      inputName,
      extraInputPatches ? { },
    }:
    mkInputPatches inputName
    ++ mkExtraInputPatches {
      inherit pkgs inputName extraInputPatches;
    };

  mkPatchedSource =
    {
      pkgs,
      inputName,
      src ? inputs.${inputName},
      extraInputPatches ? { },
      patches ? mkInputPatchList {
        inherit pkgs inputName extraInputPatches;
      },
    }:
    if patches == [ ] then
      src
    else
      pkgs.applyPatches {
        name = "${inputName}-patched";
        inherit src patches;
      };

  mkPatchedFlake =
    {
      pkgs,
      inputName,
      input ? inputs.${inputName},
      flakeInputs,
      extraInputPatches ? { },
    }:
    let
      patches = mkInputPatchList {
        inherit pkgs inputName extraInputPatches;
      };
      patchedSrc = mkPatchedSource {
        inherit pkgs inputName;
        src = input;
        inherit patches;
      };
      patchedFlake = {
        outPath = patchedSrc;
        rev = input.rev or null;
        shortRev = input.shortRev or "patched";
      }
      // (import "${patchedSrc}/flake.nix").outputs (
        flakeInputs
        // {
          self = patchedFlake;
        }
      );
    in
    if patches == [ ] then input else patchedFlake;

  mkPatchedInputs =
    {
      system,
      bootstrapInputName ? "nixpkgs-unstable",
      extraInputPatches ? { },
      patchableInputs ? [
        "nixpkgs"
        "nixpkgs-unstable"
        "nixpkgs-master"
        "home-manager"
        "nix-darwin"
      ],
    }:
    let
      enabled = inputName: builtins.elem inputName patchableInputs && builtins.hasAttr inputName inputs;
      bootstrapPkgs = inputs.${bootstrapInputName}.legacyPackages.${system};
      mkPatchedFlakeInput =
        inputName: flakeInputs:
        mkPatchedFlake {
          pkgs = bootstrapPkgs;
          inherit inputName flakeInputs;
          input = inputs.${inputName};
          inherit extraInputPatches;
        };
      patched = rec {
        nixpkgs = mkPatchedFlakeInput "nixpkgs" { };
        nixpkgs-unstable = mkPatchedFlakeInput "nixpkgs-unstable" { };
        nixpkgs-master = mkPatchedFlakeInput "nixpkgs-master" { };
        home-manager = mkPatchedFlakeInput "home-manager" {
          nixpkgs = nixpkgs-unstable;
        };
        nix-darwin = mkPatchedFlakeInput "nix-darwin" {
          nixpkgs = nixpkgs-unstable;
        };
      };
    in
    inputs
    // optionalAttrs (enabled "nixpkgs") {
      inherit (patched) nixpkgs;
    }
    // optionalAttrs (enabled "nixpkgs-unstable") {
      inherit (patched) nixpkgs-unstable;
    }
    // optionalAttrs (enabled "nixpkgs-master") {
      inherit (patched) nixpkgs-master;
    }
    // optionalAttrs (enabled "home-manager") {
      inherit (patched) home-manager;
    }
    // optionalAttrs (enabled "nix-darwin") {
      inherit (patched) nix-darwin;
    };

  mkNixpkgsConfig = flake: {
    overlays = builtins.attrValues flake.overlays;
    config = {
      allowAliases = false;
      allowUnfree = true;
      permittedInsecurePackages = [
        # NOTE: citrix
        "libxml2-2.13.8"
        "libsoup-2.74.3"
        # NOTE: needed by emulationstation
        "freeimage-3.18.0-unstable-2024-04-18"
        "mbedtls-2.28.10"
        # dev shells
        "aspnetcore-runtime-6.0.36"
        "aspnetcore-runtime-7.0.20"
        "aspnetcore-runtime-wrapped-7.0.20"
        "aspnetcore-runtime-wrapped-6.0.36"
        "dotnet-combined"
      ];
    };
  };

  mkInputPackageSets =
    {
      flake,
      system,
    }:
    let
      nixpkgsConfig = mkNixpkgsConfig flake;
      mkPkgs =
        source:
        let
          cached = import source {
            inherit system;
            inherit (nixpkgsConfig) config;
            overlays = [ ];
          };
        in
        inputSystem: inputNixpkgsConfig:
        if inputSystem == system then
          cached
        else
          import source {
            system = inputSystem;
            config = inputNixpkgsConfig.config or nixpkgsConfig.config;
            overlays = [ ];
          };

      getPkgsMaster = mkPkgs inputs.nixpkgs-master;
      getPkgsUnstable = mkPkgs inputs.nixpkgs-unstable;
    in
    {
      inherit getPkgsMaster getPkgsUnstable;
    };

  /**
    Shared Home Manager modules used by both standalone (mkHome) and integrated
    (mkHomeManagerConfig) paths. Single source of truth to prevent drift.
  */
  hmSharedModules =
    extendedLib:
    [
      inputs.catppuccin.homeModules.catppuccin
      inputs.nix-index-database.homeModules.nix-index
      inputs.sops-nix.homeManagerModules.sops
    ]
    ++ (extendedLib.importModulesRecursive ../../modules/home);
in
{
  inherit hmSharedModules;
  inherit
    mkExtraInputPatches
    mkInputPatches
    mkInputPatchList
    mkPatchedFlake
    mkPatchedInputs
    mkPatchedSource
    ;
  /**
    Create an extended library with the flake's overlay.

    # Inputs

    `flake`

    : 1\. Function argument

    `nixpkgs`

    : 2\. Function argument
  */
  mkExtendedLib = flake: nixpkgs: nixpkgs.lib.extend flake.lib.overlay;

  /**
    Create a nixpkgs configuration with overlays and unfree packages enabled.

    # Inputs

    `flake`

    : 1\. Function argument
  */
  inherit mkNixpkgsConfig mkInputPackageSets;

  /**
    Get home configurations matching a specific system and hostname.

    # Inputs

    `flake`

    : Flake instance

    `system`

    : System architecture

    `hostname`

    : Host name
  */
  mkHomeConfigs =
    {
      flake,
      system,
      hostname,
    }:
    let
      inherit (flake.lib.file) parseHomeConfigurations;
      homesPath = ../../homes;
      allHomes = parseHomeConfigurations homesPath;
    in
    filterAttrs (
      _name: homeConfig: homeConfig.system == system && homeConfig.hostname == hostname
    ) allHomes;

  /**
    Create a Home Manager configuration for a system.

    # Inputs

    `extendedLib`

    : Extended library

    `inputs`

    : Flake inputs

    `system`

    : System architecture

    `matchingHomes`

    : Matching home configurations

    `isNixOS`

    : Whether the system is NixOS
  */
  mkHomeManagerConfig =
    {
      extendedLib,
      inputs,
      system,
      hostname,
      matchingHomes,
      inputPackageSets,
      sharedHomeModules ? null,
      isNixOS ? true,
    }:
    if matchingHomes != { } then
      { config, ... }:
      let
        stylixHomeModule =
          if inputs.stylix ? homeModules && inputs.stylix.homeModules ? stylix then
            inputs.stylix.homeModules.stylix
          else
            null;
        enableStylixHomeModule = stylixHomeModule != null && !(config.stylix.enable or false);
        baseHomeModules = hmSharedModules extendedLib;
        hmSharedModulesResolved = if sharedHomeModules == null then baseHomeModules else sharedHomeModules;
      in
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit inputs system hostname;
            inherit (inputs) self;
            lib = extendedLib;
            flake-parts-lib = inputs.flake-parts.lib;
          }
          // inputPackageSets;
          sharedModules =
            hmSharedModulesResolved
            ++ extendedLib.optional enableStylixHomeModule stylixHomeModule
            # NOTE: https://github.com/nix-community/stylix/issues/1832
            ++ extendedLib.optional enableStylixHomeModule {
              stylix.overlays.enable = false;
            };
          users = mapAttrs' (_name: homeConfig: {
            name = homeConfig.username;
            value = {
              imports = [ homeConfig.path ];
              home = {
                inherit (homeConfig) username;
                homeDirectory = inputs.nixpkgs.lib.mkDefault (
                  if isNixOS then "/home/${homeConfig.username}" else "/Users/${homeConfig.username}"
                );
              };
            }
            // (
              if isNixOS then
                {
                  _module.args.username = homeConfig.username;
                }
              else
                { }
            );
          }) matchingHomes;
        };
      }
    else
      { };

  /**
    Create special arguments for system configurations.

    # Inputs

    `inputs`

    : Flake inputs

    `hostname`

    : Host name

    `username`

    : User name

    `extendedLib`

    : Extended library
  */
  mkSpecialArgs =
    {
      inputs,
      hostname,
      username,
      extendedLib,
      inputPackageSets,
    }:
    {
      inherit inputs hostname username;
      inherit (inputs) self;
      lib = extendedLib;
      flake-parts-lib = inputs.flake-parts.lib;
      format = "system";
    }
    // inputPackageSets;
}
