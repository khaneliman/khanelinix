{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.hardware.amdgpu;
in
{
  options.khanelinix.hardware.amdgpu = {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for amdgpu.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      amdgpu_top
      vulkan-tools
      nvtopPackages.amd
    ];

    environment.variables = {
      # VAAPI and VDPAU config for accelerated video.
      # See https://wiki.archlinux.org/index.php/Hardware_video_acceleration
      "VDPAU_DRIVER" = "radeonsi";
      "LIBVA_DRIVER_NAME" = "radeonsi";
    };
  };
}
