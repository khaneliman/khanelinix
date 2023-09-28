{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf mkOption;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.hardware.rgb;
in
{
  options.khanelinix.hardware.rgb = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for rgb controls.";
    ckbNextConfig = mkOpt (nullOr path) null "The ckb-next.conf file to create.";
    motherboard = mkOption {
      type = types.nullOr (types.enum [ "amd" "intel" ]);
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

    hardware.ckb-next.enable = true;

    khanelinix.home.configFile =
      { }
      // lib.optionalAttrs (cfg.ckbNextConfig != null)
        {
          "ckb-next/ckb-next.cfg".source = cfg.ckbNextConfig;
        }
      // lib.optionalAttrs (cfg.openRGBConfig != null)
        {
          "OpenRGB/sizes.ors".source = cfg.openRGBConfig + "/sizes.ors";
          "OpenRGB/Default.orp".source = cfg.openRGBConfig + "/Default.orp";
        };

    services.hardware.openrgb = {
      enable = true;
      inherit (cfg) motherboard;
    };
  };
}
