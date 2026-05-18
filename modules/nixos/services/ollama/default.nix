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

      loadModels = lib.mkDefault [
        # General agentic/reasoning model with enough headroom for the 24 GB ROCm host.
        "gpt-oss:20b"
        # Preferred local coding model for Linux; use Qwen3-Coder-Next on Apple Silicon instead.
        "qwen3-coder:30b"
        # Creative/general long-context model that is safer than the 35B tag on 24 GB VRAM.
        "qwen3.6:27b"
        # Strong 30B-class agentic/tool-use option for coding, research, and analytical tasks.
        "glm-4.7-flash"
      ];

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
