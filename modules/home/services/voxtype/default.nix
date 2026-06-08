{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.voxtype;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  options.khanelinix.services.voxtype = {
    enable = lib.mkEnableOption "Voxtype speech-to-text daemon";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "khanelinix.services.voxtype is only supported on Linux.";
        }
      ];
    })

    (lib.mkIf (cfg.enable && isLinux) {
      services.voxtype = {
        enable = true;

        package = lib.mkDefault pkgs.voxtype-vulkan;
        loadModels = lib.mkDefault [ config.services.voxtype.settings.whisper.model ];
        wayland.display = lib.mkDefault "wayland-1";
        settings = {
          state_file = lib.mkDefault "auto";
          hotkey.enabled = lib.mkDefault false;
          whisper = {
            model = lib.mkDefault "base.en";
            language = lib.mkDefault "en";
          };
        };
      };
    })
  ];
}
