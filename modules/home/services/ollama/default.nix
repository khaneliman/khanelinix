{
  config,
  lib,

  osConfig ? { },
  pkgs,
  ...
}:
let

  cfg = config.khanelinix.services.ollama;

  amdCfg = osConfig.khanelinix.hardware.gpu.amd or { };
  hasHardwareConfig = (osConfig.khanelinix.hardware or null) != null;
in
{
  options.khanelinix.services.ollama = {
    enable = lib.mkEnableOption "ollama";
    enableDebug = lib.mkEnableOption "debug";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      # FIXME: broken upstream
      enable = pkgs.stdenv.hostPlatform.isLinux;
      host = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "0.0.0.0";

      environmentVariables =
        lib.optionalAttrs cfg.enableDebug {
          OLLAMA_DEBUG = "1";
        }
        //
          lib.optionalAttrs
            (hasHardwareConfig && (amdCfg.enable or false) && (amdCfg.enableRocmSupport or false))
            {
              HCC_AMDGPU_TARGET = "gfx1100";
              HSA_OVERRIDE_GFX_VERSION = "11.0.0";
              AMD_LOG_LEVEL = lib.mkIf cfg.enableDebug "3";
            };
    };
  };
}
