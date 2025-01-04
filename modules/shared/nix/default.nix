{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  host,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.nix;
in
{
  options.${namespace}.nix = {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt lib.types.package pkgs.nixVersions.latest "Which nix package to use.";
  };

  config = lib.mkIf cfg.enable {
    # faster rebuilding
    documentation = {
      doc.enable = false;
      info.enable = false;
      man.enable = lib.mkDefault true;
    };

    environment = {
      etc =
        with inputs;
        {
          # set channels (backwards compatibility)
          "nix/flake-channels/system".source = self;
          "nix/flake-channels/nixpkgs".source = nixpkgs;
          "nix/flake-channels/home-manager".source = home-manager;
        }
        # preserve current flake in /etc
        // lib.mkIf pkgs.stdenv.isLinux {
          "nixos/flake".source = self;
        };

      systemPackages = with pkgs; [
        cachix
        deploy-rs
        git
        nix-prefetch-git
      ];
    };

    nix =
      let
        mappedRegistry = lib.pipe inputs [
          (lib.filterAttrs (_: lib.isType "flake"))
          (lib.mapAttrs (_: flake: { inherit flake; }))
          (
            x:
            x
            // {
              nixpkgs.flake = if pkgs.stdenv.isLinux then inputs.nixpkgs else inputs.nixpkgs-unstable;
            }
          )
          (x: if pkgs.stdenv.isDarwin then lib.removeAttrs x [ "nixpkgs-unstable" ] else x)
        ];

        users = [
          "root"
          "@wheel"
          "nix-builder"
          config.${namespace}.user.name
        ];
      in
      {
        inherit (cfg) package;

        buildMachines =
          let
            protocol = if pkgs.stdenv.isLinux then "ssh-ng" else "ssh";
            sshUser = "khaneliman";
            supportedFeatures = [
              "benchmark"
              "big-parallel"
              "nixos-test"
            ];
          in
          lib.optionals config.${namespace}.security.sops.enable [
            (
              lib.mkIf (host != "khanelinix") {
                inherit protocol sshUser;
                hostName = "khanelinix.local";
                systems = [
                  "x86_64-linux"
                  "aarch64-linux"
                ];
                maxJobs = 16;
                speedFactor = 10;
                supportedFeatures = supportedFeatures ++ [ "kvm" ];
              }
              // lib.optionalAttrs (host == "khanelimac") {
                sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
              }
            )
          ]
          ++ lib.optionals (config.${namespace}.security.sops.enable && pkgs.stdenv.hostPlatform.isLinux) (
            let
              systems = [
                "aarch64-darwin"
                "x86_64-darwin"
              ];
            in
            [
              (
                {
                  inherit protocol sshUser systems;
                  hostName = "khanelimac.local";
                  maxJobs = 24;
                  speedFactor = 10;
                  supportedFeatures = supportedFeatures ++ [ "apple-virt" ];
                }
                // lib.optionalAttrs (host == "khanelinix") {
                  sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
                }
              )
              (
                # NOTE: git clone --reference /var/lib/nixpkgs.git https://github.com/NixOS/nixpkgs.git
                {
                  inherit protocol sshUser systems;
                  hostName = "darwin-build-box.nix-community.org";
                  maxJobs = 32;
                  speedFactor = 5;
                  supportedFeatures = [ "big-parallel" ];
                  publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUtNSGhsY243ZlVwVXVpT0ZlSWhEcUJ6Qk5Gc2JOcXErTnB6dUdYM2U2enYgCg";
                }
                // lib.optionalAttrs (host == "khanelinix") {
                  sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
                }
                // lib.optionalAttrs (host == "khanelimac") {
                  sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
                }
              )

            ]
          );

        distributedBuilds = true;

        gc = {
          automatic = true;
          options = "--delete-older-than 7d";
        };

        # This will additionally add your inputs to the system's legacy channels
        # Making legacy nix commands consistent as well
        nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

        optimise.automatic = true;

        # pin the registry to avoid downloading and evaluating a new nixpkgs version every time
        # this will add each flake input as a registry to make nix3 commands consistent with your flake
        registry = mappedRegistry;

        settings = {
          allowed-users = users;
          auto-optimise-store = pkgs.stdenv.isLinux;
          builders-use-substitutes = true;
          # TODO: pipe-operators throws annoying warnings
          experimental-features = [
            "nix-command"
            "flakes "
          ];
          flake-registry = "/etc/nix/registry.json";
          http-connections = 50;
          keep-derivations = true;
          keep-going = true;
          keep-outputs = true;
          log-lines = 50;
          sandbox = true;
          trusted-users = users;
          warn-dirty = false;

          substituters = [
            "https://cache.nixos.org"
            "https://khanelinix.cachix.org"
            "https://nix-community.cachix.org"
            "https://nixpkgs-unfree.cachix.org"
            "https://numtide.cachix.org"
          ];

          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "khanelinix.cachix.org-1:FTmbv7OqlMsmJEOFvAlz7PVkoGtstbwLC2OldAiJZ10="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];

          use-xdg-base-directories = true;
        };
      };

    programs.ssh.knownHosts = {
      "aarch64.nixos.community".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";
      "darwin-build-box.nix-community.org".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFz8FXSVEdf8FvDMfboxhB5VjSe7y2WgSa09q1L4t099";
      "khanelimac".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD";
      "khanelinix".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC";
    };
  };
}
