{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  ollamaEnabled =
    (config.services.ollama.enable or false) || (osConfig.services.ollama.enable or false);

  swapCfg = osConfig.khanelinix.services.llm.llamaSwap or { };

  # The proxy publishes its own base URL, so a host or port change needs no edit
  # here. Fall back to the upstream default when this user has no such host,
  # which keeps the provider usable against a proxy elsewhere.
  swapEndpoint = swapCfg.endpoint or "http://127.0.0.1:8090/v1";

  swapEnabled = swapCfg.enable or false;
in
{
  config = {
    programs.opencode.settings.provider = {
      exo = lib.mkIf config.services.exo.enable {
        npm = "@ai-sdk/openai-compatible";
        name = "exo (local cluster)";
        options = {
          baseURL = "http://localhost:52415/v1";
        };
        models = {
          "mlx-community/Qwen3-Coder-Next-4bit".name = "Qwen3 Coder Next 4bit";
          "mlx-community/Qwen3.6-35B-A3B-5bit".name = "Qwen3.6 35B A3B 5bit";
          "mlx-community/gpt-oss-20b-MXFP4-Q8".name = "GPT OSS 20B MXFP4 Q8";
        };
      };

      # Two managers on one card evict each other's weights, so each model is
      # reached through the service that owns it. llama-swap loads one model at a
      # time and unloads on a timer; ollama keeps the tags llama.cpp cannot read.
      llama-swap = lib.mkIf swapEnabled {
        npm = "@ai-sdk/openai-compatible";
        name = "Local (llama-swap)";
        options = {
          baseURL = swapEndpoint;
        };
        models = {
          "qwen3-6-27b".name = "Qwen3.6 27B";
          "qwen3-coder-30b".name = "Qwen3 Coder 30B";
          "qwen36-colibri".name = "Qwen3.6 35B-A3B (streamed)";
        };
      };

      ollama = lib.mkIf ollamaEnabled {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options = {
          baseURL = "http://localhost:11434/v1";
        };
        # ollama converts these with its own architecture names, so no other
        # engine here can load them.
        models = {
          "glm-4.7-flash".name = "GLM 4.7 Flash";
          "gpt-oss:20b".name = "GPT OSS 20B";
        };
      };
    };
  };
}
