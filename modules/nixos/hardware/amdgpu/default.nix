{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.hardware.amdgpu;
in
{
  options.khanelinix.hardware.amdgpu = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for amdgpu.";
  };

  config = mkIf cfg.enable {
    # hardware.amdgpu.amdvlk = true;

    environment.systemPackages = with pkgs; [ radeontop ];

    environment.variables = {
      # VAAPI and VDPAU config for accelerated video.
      # See https://wiki.archlinux.org/index.php/Hardware_video_acceleration
      "VDPAU_DRIVER" = "radeonsi";
      "LIBVA_DRIVER_NAME" = "radeonsi";
    };
  };
}
