{
  config,
  lib,
  hostname,
  ...
}:
let
  cfg = config.khanelinix.nix;
  homeCfg = config.home-manager.users.${config.khanelinix.user.name} or { };
  aiDevelopmentEnabled = homeCfg.khanelinix.suites.development.aiEnable or false;
  khanelivimEnabled = homeCfg.khanelinix.programs.terminal.editors.neovim.enable or false;
  hasRemoteBuilders =
    config.khanelinix.security.sops.enable
    && (config.khanelinix.environments.home-network.enable or false);

in
{
  khanelinix.nix.localCaches = lib.mkOptionDefault {
    khanelinix = "khanelinix.local-1:nIZrdCkkwLNueBa7lFeEaktr6zicYPyblSHy2YGnHKU=";
    khanelimac = "khanelimac.local-1:4UhAD8PShI7Kb6Lwrsh/T9W52xI/IBtjg7qRFbJpNBA=";
  };
  nix = lib.mkIf cfg.enable {
    buildMachines =
      let
        sshUser = "khaneliman";
        protocol = "ssh-ng";
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "nixos-test"
        ];
      in
      # Linux and Darwin builders are only reachable on the home network.
      lib.optionals hasRemoteBuilders [
        /*
          NOTE: Disabled due to host being unreachable and causing build hangs
          (
            lib.mkIf (hostname != "bruddynix" && hostname != "khanelinix") {
              inherit sshUser;
              hostName = "bruddynix.local";
              systems = [
                "x86_64-linux"
              ];
              maxJobs = 2;
              speedFactor = 1;
              inherit protocol supportedFeatures;
            }
            // lib.optionalAttrs (hostname == "khanelimac") {
              sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
            }
          )
        */
        (lib.mkIf (hostname != "khanelinix") (
          {
            inherit protocol sshUser;
            hostName = "khanelinix.local";
            systems = [
              "x86_64-linux"
            ];
            maxJobs = 4;
            speedFactor = 2;
            supportedFeatures = supportedFeatures ++ [ "kvm" ];
          }
          // lib.optionalAttrs (hostname == "khanelimac") {
            sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
          }
        ))
        (
          {
            inherit protocol sshUser;
            hostName = "aarch64-build-box.nix-community.org";
            maxJobs = 10;
            speedFactor = 1;
            systems = [
              "aarch64-linux"
            ];
            supportedFeatures = [
              "big-parallel"
              "kvm"
              "nixos-test"
            ];
          }
          // lib.optionalAttrs (hostname == "khanelimac") {
            sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
          }
          // lib.optionalAttrs (hostname == "khanelinix") {
            sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
          }
        )
        # Darwin builders
        (lib.mkIf (hostname != "khanelimac") (
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
          // lib.optionalAttrs (hostname == "khanelinix") {
            sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
          }
        ))
        (lib.mkIf (hostname != "khanelimac-m1") (
          {
            inherit protocol sshUser;
            systems = [
              "aarch64-darwin"
              "x86_64-darwin"
            ];
            hostName = "khanelimac-m1.local";
            maxJobs = 2;
            speedFactor = 5;
            supportedFeatures = supportedFeatures ++ [ "apple-virt" ];
          }
          // lib.optionalAttrs (hostname == "khanelinix") {
            sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
          }
          // lib.optionalAttrs (hostname == "khanelimac") {
            sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
            # Prefer local builds for personal usage
            systems = [
              "x86_64-darwin"
            ];
          }
        ))
        (lib.mkIf (hostname != "khanelimac") (
          # NOTE: git clone --reference /var/lib/nixpkgs.git https://github.com/NixOS/nixpkgs.git
          {
            inherit protocol sshUser;
            systems = [
              "aarch64-darwin"
            ];
            hostName = "darwin-build-box.nix-community.org";
            maxJobs = 3;
            speedFactor = 3;
            supportedFeatures = [ "big-parallel" ];
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUtNSGhsY243ZlVwVXVpT0ZlSWhEcUJ6Qk5Gc2JOcXErTnB6dUdYM2U2enYgCg";
          }
          // lib.optionalAttrs (hostname == "khanelinix") {
            sshKey = config.sops.secrets.khanelinix_khaneliman_ssh_key.path;
          }
          // lib.optionalAttrs (hostname == "khanelimac-m1") {
            sshKey = config.sops.secrets.khanelimac_khaneliman_ssh_key.path;
          }
        ))
      ];

    settings = {
      substituters = [
        "https://khanelinix.cachix.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
      ]
      ++ lib.optionals khanelivimEnabled [ "https://khanelivim.cachix.org" ]
      ++ lib.optionals aiDevelopmentEnabled [ "https://cache.numtide.com" ];

      trusted-public-keys = [
        "khanelinix.cachix.org-1:FTmbv7OqlMsmJEOFvAlz7PVkoGtstbwLC2OldAiJZ10="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      ]
      ++ lib.optionals khanelivimEnabled [
        "khanelivim.cachix.org-1:Tb0jsMlhXSJDtI2ISiGPBrvL1XIzQrWap80AiJuBGI0="
      ]
      ++ lib.optionals aiDevelopmentEnabled [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];

    };
  };
}
