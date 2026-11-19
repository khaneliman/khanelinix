{
  config,
  lib,
  pkgs,
  ...
}:
let
  llmCfg = config.khanelinix.services.llm;
  cfg = llmCfg.gpuCoordination;
  amdCfg = config.khanelinix.hardware.gpu.amd;
  swapCfg = llmCfg.llamaSwap;
  ollamaCfg = config.services.ollama;

  localAddress =
    host:
    {
      "0.0.0.0" = "127.0.0.1";
      "127.0.0.1" = "127.0.0.1";
      "[::]" = "[::1]";
      "[::1]" = "[::1]";
      localhost = "localhost";
    }
    .${host} or null;
  swapHost = localAddress swapCfg.host;
  ollamaHost = localAddress ollamaCfg.host;
  hasRocm = amdCfg.enable && amdCfg.enableRocmSupport;
  hasServices = llmCfg.enable && swapCfg.enable && ollamaCfg.enable;
  hasLocalEndpoints = swapHost != null && ollamaHost != null;

  helper = pkgs.writeShellApplication {
    name = "llm-gpu";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      swap_url=${lib.escapeShellArg "http://${swapHost}:${toString swapCfg.port}"}
      ollama_url=${lib.escapeShellArg "http://${ollamaHost}:${toString ollamaCfg.port}"}
      ${builtins.readFile ./llm-gpu.sh}
    '';
  };
in
{
  options.khanelinix.services.llm.gpuCoordination.enable = lib.mkEnableOption ''
    the llm-gpu command to inspect or manually unload local models when
    switching between llama-swap, Ollama, and desktop GPU workloads
  '';

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = hasRocm;
        message = "khanelinix.services.llm.gpuCoordination requires AMD GPU and ROCm support.";
      }
      {
        assertion = hasServices;
        message = "khanelinix.services.llm.gpuCoordination requires local llama-swap and Ollama.";
      }
      {
        assertion = hasLocalEndpoints;
        message = "khanelinix.services.llm.gpuCoordination requires the model servers to listen on loopback or wildcard addresses.";
      }
    ];

    environment.systemPackages = lib.mkIf (hasRocm && hasServices && hasLocalEndpoints) [ helper ];
  };
}
