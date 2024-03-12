{ config
, lib
, ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.internal) enabled disabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    apps = {
      vscode = mkForce disabled;

      firefox = {
        hardwareDecoding = true;
        settings = {
          "dom.ipc.processCount.webIsolated" = 9;
          "dom.maxHardwareConcurrency" = 16;
          "media.av1.enabled" = false;
          "media.ffvpx.enabled" = false;
          "media.hardware-video-decoding.force-enabled" = true;
          "media.hardwaremediakeys.enabled" = true;
          "media.navigator.mediadatadecoder_vpx_enabled" = true;
          "media.rdd-vpx.enabled" = false;
        };
      };
    };

    cli-apps = {
      home-manager = enabled;
      cava = enabled;
    };

    desktop = {
      addons = {
        sketchybar = enabled;
      };
    };

    security = {
      sops = {
        enable = true;
        defaultSopsFile = ../../../secrets/khanelimac/khaneliman/default.yaml;
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    suites = {
      business = enabled;
      common = enabled;
      development = enabled;
      social = enabled;
      music = enabled;
    };

    tools = {
      ssh = {
        enable = true;

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7UBwfd7+K0mdkAIb2TE6RzMu6L4wZnG/anuoYqJMPB"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC"
        ];
      };
    };
  };

  home.shellAliases = {
    nixcfg = "nvim ~/.config/.dotfiles/dots/nixos/flake.nix";
  };

  home.stateVersion = "21.11";
}
