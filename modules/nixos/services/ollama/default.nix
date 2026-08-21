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

      # A static identity lets sibling services read the model store. The
      # default DynamicUser owns the blobs as a rotating uid, and systemd
      # rewrites that ownership whenever the uid changes.
      user = "ollama";
      group = "ollama";

      loadModels = lib.mkDefault [
        # General agentic/reasoning model with enough headroom for the 24 GB ROCm host.
        "gpt-oss:20b"
        # Preferred local coding model for Linux; use Qwen3-Coder-Next on Apple Silicon instead.
        "qwen3-coder:30b"
        # Creative/general long-context model that is safer than the 35B tag on 24 GB VRAM.
        "qwen3.6:27b"
        # Strong 30B-class agentic/tool-use option for coding, research, and analytical tasks.
        "glm-4.7-flash"
        # Editor completion at the cursor. Only a base tag carries the template
        # that splits the text before the cursor from the text after it, and
        # ollama ships no Qwen3-Coder base tag. The 1.5B tag stays resident
        # beside a 30B coder on 24 GB VRAM.
        "qwen2.5-coder:1.5b-base"
        # Retrieval embeddings for local document search and RAG.
        "qwen3-embedding:0.6b"
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

    # The store predates the static identity, so its files still belong to the
    # retired dynamic uid. Reclaim them for the ollama user.
    systemd.tmpfiles.rules = [
      "Z /var/lib/private/ollama - ollama ollama - -"
    ];
  };
}
