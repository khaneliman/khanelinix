{
  config,
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.nix;
  localCaches = lib.optionalAttrs (config.khanelinix.environments.home-network.enable or false) (
    lib.filterAttrs (name: _: name != config.networking.hostName) cfg.localCaches
  );
  nhCleanEnabled =
    config.khanelinix.user.name != null
    && lib.attrByPath [
      "home-manager"
      "users"
      config.khanelinix.user.name
      "khanelinix"
      "programs"
      "terminal"
      "tools"
      "nh"
      "enable"
    ] false config;

in
{
  options.khanelinix.nix = {
    enable = mkBoolOpt false "Whether or not to manage nix configuration.";
    useLix = mkBoolOpt false "Whether or not to use Lix.";
    package = mkOpt lib.types.package pkgs.nixVersions.latest "Which nix package to use.";
    localCaches =
      mkOpt (lib.types.attrsOf lib.types.str) { }
        "Explicit LAN cache hostnames and public keys.";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = lib.optional cfg.useLix (
      _final: prev: {
        inherit (inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.lixPackageSets.stable)
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
          ;
      }
    );

    # faster rebuilding
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = lib.mkDefault true;
    };

    environment = {
      etc = {
        # set channels (backwards compatibility)
        "nix/flake-channels/system".source = self;
        "nix/flake-channels/nixpkgs".source = inputs.nixpkgs;
        "nix/flake-channels/home-manager".source = inputs.home-manager;
      }
      # preserve current flake in /etc
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        "nixos".source = self;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        "nix-darwin".source = self;
      }
      # Create /etc/nix/inputs symlinks for all flake inputs
      // lib.mapAttrs' (
        name: input:
        lib.nameValuePair "nix/inputs/${name}" {
          source = input.outPath or input;
        }
      ) inputs;

      systemPackages = with pkgs; [
        git
        nix-prefetch-git
      ];
    };

    # Shared config options
    # Check corresponding nixos/nix-darwin imported module
    nix =
      let
        isLix = cfg.useLix || (lib.getName cfg.package) == "lix";
        experimentalFeatures = [
          "nix-command"
          "flakes"
          "ca-derivations"
          "dynamic-derivations"
          (if isLix then "pipe-operator" else "pipe-operators")
        ]
        ++ lib.optional pkgs.stdenv.hostPlatform.isLinux "auto-allocate-uids";
      in
      {
        package =
          if cfg.useLix then
            (pkgs.lixPackageSets.stable.lix.overrideAttrs {
              doInstallCheck = pkgs.stdenv.hostPlatform.isLinux;
            })
          else
            cfg.package;

        checkConfig = true;
        distributedBuilds = lib.mkDefault (config.nix.buildMachines != [ ]);
        gc.automatic = lib.mkDefault (pkgs.stdenv.hostPlatform.isDarwin || !nhCleanEnabled);

        # This will additionally add your inputs to the system's legacy channels
        # Making legacy nix commands consistent as well
        # NOTE: We link inputs here
        nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
        optimise.automatic = true;

        # pin the registry to avoid downloading and evaluating a new nixpkgs version every time
        # this will add each flake input as a registry to make nix3 commands consistent with your flake
        registry = lib.pipe inputs [
          (lib.filterAttrs (_: lib.isType "flake"))
          (lib.mapAttrs (_: flake: { inherit flake; }))
          (
            x:
            x
            // {
              nixpkgs.flake =
                if pkgs.stdenv.hostPlatform.isLinux then inputs.nixpkgs else inputs.nixpkgs-unstable;
            }
          )
          (x: if pkgs.stdenv.hostPlatform.isDarwin then lib.removeAttrs x [ "nixpkgs-unstable" ] else x)
        ];

        settings = {
          substituters = lib.mkIf (localCaches != { }) (
            lib.mapAttrsToList (name: _: "http://${name}.local:5020") localCaches
          );
          trusted-public-keys = lib.mkIf (localCaches != { }) (lib.attrValues localCaches);
          allowed-users = lib.mkIf (config.khanelinix.user.name != null) [
            config.khanelinix.user.name
          ];
          auto-optimise-store = pkgs.stdenv.hostPlatform.isLinux;
          builders-use-substitutes = true;
          experimental-features = experimentalFeatures;
          # Prevent builds failing just because we can't contact a substituter
          fallback = true;
          # The harmonia substituters are only reachable on the home LAN; fail
          # over to the public caches quickly when they are absent.
          connect-timeout = 5;
          flake-registry = "/etc/nix/registry.json";
          log-lines = 50;
          sandbox = true;
          trusted-users = lib.optional (config.khanelinix.user.name != null) config.khanelinix.user.name;
          min-free = 1073741824; # 1GB
          max-free = 10737418240; # 10GB
          keep-going = true;

          use-xdg-base-directories = true;
        };
      };
  };
}
