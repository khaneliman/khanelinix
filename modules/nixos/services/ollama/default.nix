{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.ollama;

  amdCfg = config.khanelinix.hardware.gpu.amd;

in
{
  options.${namespace}.services.ollama = {
    enable = mkBoolOpt false "Whether to enable ollama.";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      rocmOverrideGfx = lib.mkIf (amdCfg.enable && amdCfg.enableRocmSupport) "11.0.2";

      environmentVariables =
        {
          OLLAMA_DEBUG = "1";
        }
        // lib.optionalAttrs (amdCfg.enable && amdCfg.enableRocmSupport) {
          HCC_AMDGPU_TARGET = "gfx1102";
          AMD_LOG_LEVEL = "3";
        };
    };
  };
}
