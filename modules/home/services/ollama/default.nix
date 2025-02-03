{
  config,
  lib,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.ollama;

  amdCfg = osConfig.khanelinix.hardware.gpu.amd;
in
{
  options.${namespace}.services.ollama = {
    enable = mkBoolOpt false "Whether to enable ollama.";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;

      environmentVariables =
        {
          OLLAMA_DEBUG = "1";
        }
        // lib.optionalAttrs (amdCfg.enable && amdCfg.enableRocmSupport) {
          HCC_AMDGPU_TARGET = "gfx1102";
          HSA_OVERRIDE_GFX_VERSION = "11.0.2";
          AMD_LOG_LEVEL = "3";
        };
    };
  };
}
