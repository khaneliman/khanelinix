{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) types mkIf mkForce;
  inherit (khanelinix-lib) mkBoolOpt mkOpt;

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
    modules = mkOpt (listOf attrs) [ ] "Audio modules to pass to Pipewire as `context.modules`.";
    nodes = mkOpt (listOf attrs) [ ] "Audio nodes to pass to Pipewire as `context.objects`.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        pulsemixer
        pavucontrol
        helvum
      ]
      ++ cfg.extra-packages;

    khanelinix = {
      user.extraGroups = [ "audio" ];
    };

    security.rtkit.enable = true;

    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        audio.enable = true;
        jack.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
      pulseaudio.enable = mkForce false;
    };
  };
}
