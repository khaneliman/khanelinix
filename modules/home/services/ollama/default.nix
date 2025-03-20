{
  config,
  lib,
  namespace,
  osConfig,
  pkgs,
  ...
}:
let

  cfg = config.${namespace}.services.ollama;

  amdCfg = osConfig.khanelinix.hardware.gpu.amd;
  hasHardwareConfig = lib.hasAttr "hardware" osConfig.khanelinix;
in
{
  options.${namespace}.services.ollama = {
    enable = lib.mkEnableOption "ollama";
    enableDebug = lib.mkEnableOption "debug";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      host = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "0.0.0.0";

      environmentVariables =
        lib.optionalAttrs cfg.enableDebug {
          OLLAMA_DEBUG = "1";
        }
        // lib.optionalAttrs (hasHardwareConfig && amdCfg.enable && amdCfg.enableRocmSupport) {
          HCC_AMDGPU_TARGET = "gfx1100";
          HSA_OVERRIDE_GFX_VERSION = "11.0.0";
          AMD_LOG_LEVEL = lib.mkIf cfg.enableDebug "3";
        };
    };
  };
}
