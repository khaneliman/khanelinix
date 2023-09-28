{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf mkForce getExe';
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.hardware.audio;
in
{
  options.khanelinix.hardware.audio = with types; {
    enable = mkBoolOpt false "Whether or not to enable audio support.";
    alsa-monitor = mkOpt attrs { } "Alsa configuration.";
    extra-packages = mkOpt (listOf package) [
      pkgs.qjackctl
      pkgs.easyeffects
    ] "Additional packages to install.";
    modules =
      mkOpt (listOf attrs) [ ]
        "Audio modules to pass to Pipewire as `context.modules`.";
    nodes =
      mkOpt (listOf attrs) [ ]
        "Audio nodes to pass to Pipewire as `context.objects`.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        pulsemixer
        pavucontrol
        helvum
      ]
      ++ cfg.extra-packages;

    hardware.pulseaudio.enable = mkForce false;

    khanelinix = {
      home.extraOptions = {
        systemd.user.services.mpris-proxy = {
          Unit.Description = "Mpris proxy";
          Unit.After = [ "network.target" "sound.target" ];
          Service.ExecStart = "${getExe' pkgs.bluez "mpris-proxy"}";
          Install.WantedBy = [ "default.target" ];
        };
      };

      user.extraGroups = [ "audio" ];
    };

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

  };
}
