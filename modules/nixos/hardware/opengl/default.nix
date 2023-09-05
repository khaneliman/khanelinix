{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.hardware.opengl;
in
{
  options.khanelinix.hardware.opengl = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for opengl.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vdpauinfo
      libva-utils
    ];

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        libva
        libvdpau
        libdrm
      ]; #++ lib.optional config.khanelinix.hardware.amdgpu.enable pkgs.mesa-vdpau;
    };
  };
}
