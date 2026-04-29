{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkForce mkIf types;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.hardware.audio;

  profileSettings = {
    desktop = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 512;
      "default.clock.min-quantum" = 256;
      "default.clock.max-quantum" = 8192;
    };
    creation = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 256;
      "default.clock.min-quantum" = 128;
      "default.clock.max-quantum" = 8192;
    };
  };
in
{
  options.khanelinix.hardware.audio = {
    enable = lib.mkEnableOption "audio support";
    alsa-monitor = mkOpt types.attrs { } "Alsa monitor properties to pass to WirePlumber.";
    extra-packages = mkOpt (types.listOf types.package) [
      pkgs.qjackctl
      pkgs.easyeffects
    ] "Additional packages to install.";
    modules =
      mkOpt (types.listOf types.attrs) [ ]
        "Audio modules to pass to Pipewire as `context.modules`.";
    nodes =
      mkOpt (types.listOf types.attrs) [ ]
        "Audio nodes to pass to Pipewire as `context.objects`.";
    profile = mkOpt (types.enum [
      "desktop"
      "creation"
    ]) "desktop" "PipeWire latency profile.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        crosspipe
        pulsemixer
        pavucontrol
        pwvucontrol
        qpwgraph
      ]
      ++ cfg.extra-packages;

    khanelinix = {
      user.extraGroups = [ "audio" ];
    };

    # Disable audio power saving to prevent crackling
    boot.extraModprobeConfig = ''
      options snd_hda_intel power_save=0
    '';

    security.rtkit.enable = true;

    services = {
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = pkgs.stdenv.hostPlatform.isx86_64;
        };
        audio.enable = true;
        jack.enable = true;
        pulse.enable = true;
        wireplumber = {
          enable = true;
          extraConfig = {
            "50-bluez" = {
              "monitor.bluez.properties" = {
                "bluez5.enable-sbc-xq" = true;
                "bluez5.default.rate" = 48000;
                "bluez5.default.channels" = 2;
                "bluez5.dummy-avrcp-player" = true;
              };
              "monitor.bluez.rules" = [
                {
                  matches = [
                    {
                      "device.name" = "~bluez_card.*";
                    }
                  ];
                  actions.update-props = {
                    "bluez5.auto-connect" = [
                      "hfp_hf"
                      "a2dp_sink"
                    ];
                    "bluez5.hw-volume" = [
                      "hfp_hf"
                      "a2dp_sink"
                    ];
                    "bluez5.a2dp.ldac.quality" = "auto";
                    "bluez5.a2dp.aac.bitratemode" = 0;
                    "bluez5.a2dp.opus.pro.application" = "audio";
                    "bluez5.a2dp.opus.pro.bidi.application" = "audio";
                  };
                }
              ];
            };
          }
          // lib.optionalAttrs (cfg.alsa-monitor != { }) {
            "50-alsa" = {
              "monitor.alsa.properties" = cfg.alsa-monitor;
            };
          };
        };
        extraConfig.pipewire = {
          "50-audio-profile" = {
            "context.properties" = profileSettings.${cfg.profile};
          };
        }
        // lib.optionalAttrs (cfg.modules != [ ]) {
          "60-audio-modules" = {
            "context.modules" = cfg.modules;
          };
        }
        // lib.optionalAttrs (cfg.nodes != [ ]) {
          "60-audio-nodes" = {
            "context.objects" = cfg.nodes;
          };
        };
      };
      pulseaudio.enable = mkForce false;
    };
  };
}
