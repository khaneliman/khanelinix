{ config, lib, ... }:
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

      ollama = lib.mkIf config.services.ollama.enable {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options = {
          baseURL = "http://localhost:11434/v1";
        };
        models = {
          "gpt-oss" = {
            name = "GPT OSS";
          };
        };
      };
    };
  };
}
