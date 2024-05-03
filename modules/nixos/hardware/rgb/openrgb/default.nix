{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkIf mkOption;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.hardware.rgb.openrgb;
in
{
  options.khanelinix.hardware.rgb.openrgb = with types; {
    enable = mkBoolOpt false "Whether or not to enable support for rgb controls.";
    motherboard = mkOption {
      type = types.nullOr (
        types.enum [
          "amd"
          "intel"
        ]
      );
      default = "amd";
      description = lib.mdDoc "CPU family of motherboard. Allows for addition motherboard i2c support.";
    };
    openRGBConfig = mkOpt (nullOr path) null "The openrgb file to create.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      i2c-tools
      openrgb-with-all-plugins
    ];

    khanelinix.home.configFile =
      { }
      // lib.optionalAttrs (cfg.openRGBConfig != null) {
        "OpenRGB/sizes.ors".source = cfg.openRGBConfig + "/sizes.ors";
        "OpenRGB/Default.orp".source = cfg.openRGBConfig + "/Default.orp";
      };

    services.hardware.openrgb = {
      enable = true;
      inherit (cfg) motherboard;
    };
  };
}
