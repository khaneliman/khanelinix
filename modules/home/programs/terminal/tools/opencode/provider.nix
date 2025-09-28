{ config, lib, ... }:
{
  config = {
    programs.opencode.settings.provider = {
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
