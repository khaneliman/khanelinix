{
  config,
  inputs,
  lib,
  pkgs,
  self,

  host,
  ...
}:
let
  inherit (lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.nix;
in
{
  options.khanelinix.nix = {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    useLix = mkBoolOpt false "Whether or not to use Lix.";
    package = mkOpt lib.types.package pkgs.nixVersions.latest "Which nix package to use.";
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
      # preserve current flake in /etc
      etc =
        lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          "nixos".source = self;
        }
        // lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          "nix-darwin".source = self;
        };

      systemPackages = with pkgs; [
        git
        nix-prefetch-git
      ];
    };

    # Shared config options
    # Check corresponding nixos/nix-darwin imported module
    nix =
      let
        users = [
          "root"
          "@wheel"
          "nix-builder"
          config.khanelinix.user.name
        ];

        isLix = cfg.useLix || (lib.getName cfg.package) == "lix";
      in
      {
        package = if cfg.useLix then pkgs.lixPackageSets.stable.lix else cfg.package;

        buildMachines =
          let
            sshUser = "khaneliman";
            # TODO: update when ssh-ng isn't so slow
            # protocol = if pkgs.stdenv.hostPlatform.isLinux then "ssh-ng" else "ssh";
            protocol = "ssh";
            supportedFeatures = [
              "benchmark"
              "big-parallel"
              "nixos-test"
            ];
          in
          # Linux builders
          lib.optionals config.khanelinix.security.sops.enable [
            (
              lib.mkIf (host != "bruddynix" && host != "khanelinix") {
                inherit sshUser;
                hostName = "bruddynix.local";
                systems = [
                  "x86_64-linux"
                ];
                maxJobs = 2;
                speedFactor = 1;
                inherit protocol supportedFeatures;
              }
              // lib.optionalAttrs (host == "khanelimac") {
                sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
              }
            )
            (
              {
                inherit protocol sshUser;
                hostName = "khanelinix.local";
                systems = [
                  "x86_64-linux"
                ];
                maxJobs = 6;
                speedFactor = 2;
                supportedFeatures = supportedFeatures ++ [ "kvm" ];
              }
              // lib.optionalAttrs (host == "khanelimac") {
                sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
              }
              // lib.optionalAttrs (host == "khanelinix") {
                sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
                maxJobs = 0;
              }
            )
            (
              {
                inherit protocol sshUser;
                hostName = "aarch64-build-box.nix-community.org";
                maxJobs = 10;
                speedFactor = 1;
                system = "aarch64-linux";
                supportedFeatures = [
                  "big-parallel"
                  "kvm"
                  "nixos-test"
                ];
              }
              // lib.optionalAttrs (host == "khanelimac") {
                sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
              }
              // lib.optionalAttrs (host == "khanelinix") {
                sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
              }
            )
            # Darwin builders
            (
              {
                inherit protocol sshUser;
                systems = [
                  "aarch64-darwin"
                  "x86_64-darwin"
                ];
                hostName = "khanelimac.local";
                maxJobs = 4;
                speedFactor = 10;
                supportedFeatures = supportedFeatures ++ [ "apple-virt" ];
              }
              // lib.optionalAttrs (host == "khanelinix") {
                sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
              }
              // lib.optionalAttrs (host == "khanelinix") {
                sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
                maxJobs = 0;
              }
            )
            (
              {
                inherit protocol sshUser;
                systems = [
                  "aarch64-darwin"
                  "x86_64-darwin"
                ];
                hostName = "khanelimac-m1.local";
                maxJobs = 2;
                speedFactor = 3;
                supportedFeatures = supportedFeatures ++ [ "apple-virt" ];
              }
              // lib.optionalAttrs (host == "khanelinix") {
                sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
              }
              // lib.optionalAttrs (host == "khanelimac") {
                sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
                # Prefer local builds for personal usage
                systems = [
                  "x86_64-darwin"
                ];
              }
            )
            (
              # NOTE: git clone --reference /var/lib/nixpkgs.git https://github.com/NixOS/nixpkgs.git
              {
                inherit protocol sshUser;
                systems = [
                  "aarch64-darwin"
                ];
                hostName = "darwin-build-box.nix-community.org";
                maxJobs = 3;
                speedFactor = 5;
                supportedFeatures = [ "big-parallel" ];
                publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUtNSGhsY243ZlVwVXVpT0ZlSWhEcUJ6Qk5Gc2JOcXErTnB6dUdYM2U2enYgCg";
              }
              // lib.optionalAttrs (host == "khanelinix") {
                sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
              }
              # TODO: figure out preferring local over remote
              // lib.optionalAttrs (host == "khanelimac") {
                sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
                maxJobs = 0;
              }
            )
          ];

        checkConfig = true;
        distributedBuilds = true;
        gc.automatic = true;

        # This will additionally add your inputs to the system's legacy channels
        # Making legacy nix commands consistent as well
        # NOTE: We link inputs here
        nixPath = [ "nixpkgs=flake:nixpkgs" ];
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
          allowed-users = users;
          auto-optimise-store = pkgs.stdenv.hostPlatform.isLinux;
          builders-use-substitutes = true;
          experimental-features = [
            "nix-command"
            "flakes"
            "auto-allocate-uids"
          ]
          ++ lib.optionals (!isLix) [
            "ca-derivations"
            "pipe-operators"
            "dynamic-derivations"
          ];
          # Prevent builds failing just because we can't contact a substituter
          fallback = true;
          flake-registry = "/etc/nix/registry.json";
          http-connections = 0;
          keep-derivations = true;
          keep-going = true;
          keep-outputs = true;
          log-lines = 50;
          preallocate-contents = true;
          sandbox = true;
          trusted-users = users;
          warn-dirty = false;

          allowed-impure-host-deps = [
            # Only wanted to add this for darwin from nixos
            # But, apparently using option wipes out all the other in the default list
            "/bin/sh"
            "/dev/random"
            "/dev/urandom"
            "/dev/zero"
            "/usr/bin/ditto"
            "/usr/lib/libSystem.B.dylib"
            "/usr/lib/libc.dylib"
            "/usr/lib/system/libunc.dylib"
          ];

          substituters = [
            "https://cache.nixos.org"
            "https://khanelinix.cachix.org"
            "https://khanelivim.cachix.org"
            "https://nix-community.cachix.org"
            "https://nixpkgs-unfree.cachix.org"
            "https://numtide.cachix.org"
          ];

          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "khanelinix.cachix.org-1:FTmbv7OqlMsmJEOFvAlz7PVkoGtstbwLC2OldAiJZ10="
            "khanelivim.cachix.org-1:Tb0jsMlhXSJDtI2ISiGPBrvL1XIzQrWap80AiJuBGI0="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];

          use-xdg-base-directories = true;
        }
        // lib.optionalAttrs (!isLix) {
          download-buffer-size = 500000000;
        };
      };
  };
}
