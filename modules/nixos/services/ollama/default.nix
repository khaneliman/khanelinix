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

      environmentVariables = {
        # A desktop compositor needs video memory too, and a 24 GiB card holds
        # about one of these models. Holding weights for the upstream default
        # of five minutes after a one-shot completion starves the desktop and
        # collides with llama-swap, which manages the same card without
        # knowing about this service.
        OLLAMA_KEEP_ALIVE = "60s";

        # A second resident model cannot fit, so loading one only pushes the
        # first onto the CPU.
        OLLAMA_MAX_LOADED_MODELS = "1";

        # Same trade-off as the llama-swap kvCacheType default: on this card a
        # q8_0 cache measured 177 tokens per second against 154 for f16 and
        # freed 1.3 GiB at 32768 context. Flash attention resolves to auto.
        OLLAMA_KV_CACHE_TYPE = "q8_0";
      }
      // lib.optionalAttrs cfg.enableDebug {
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
