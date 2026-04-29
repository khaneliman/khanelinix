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
    alsa-monitor = mkOpt types.attrs { } "Alsa configuration.";
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
        wireplumber.enable = true;
        extraConfig.pipewire."50-audio-profile" = {
          "context.properties" = profileSettings.${cfg.profile};
        };
      };
      pulseaudio.enable = mkForce false;
    };
  };
}
