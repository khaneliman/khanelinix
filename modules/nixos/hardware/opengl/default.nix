{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.hardware.opengl;
in
{
  options.khanelinix.hardware.opengl = {
    enable = lib.mkEnableOption "support for opengl";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libva-utils
      vdpauinfo
    ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        libva
        libvdpau
        libdrm
      ];
    };

    khanelinix.user.extraGroups = [
      "render"
      "video"
    ];
  };
}
