{
  config,
  lib,

  ...
}:
let

  cfg = config.khanelinix.services.ollama;

  amdCfg = config.khanelinix.hardware.gpu.amd;

in
{
  options.khanelinix.services.ollama = {
    enable = lib.mkEnableOption "ollama";
    enableDebug = lib.mkEnableOption "debug";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;

      openFirewall = true;

      rocmOverrideGfx = lib.mkIf (amdCfg.enable && amdCfg.enableRocmSupport) "11.0.0";

      environmentVariables =
        lib.optionalAttrs cfg.enableDebug {
          OLLAMA_DEBUG = "1";
        }
        // lib.optionalAttrs (amdCfg.enable && amdCfg.enableRocmSupport) {
          HCC_AMDGPU_TARGET = "gfx1100";
          AMD_LOG_LEVEL = lib.mkIf cfg.enableDebug "3";
        };
    };
  };
}
