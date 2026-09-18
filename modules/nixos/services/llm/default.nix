{
  config,
  lib,
  pkgs,

  ...
}:
let

  cfg = config.khanelinix.services.llm;

  amdCfg = config.khanelinix.hardware.gpu.amd;
  nvidiaCfg = config.khanelinix.hardware.gpu.nvidia;

  resolvedAcceleration =
    if cfg.acceleration != "auto" then
      cfg.acceleration
    else if nvidiaCfg.enable then
      "cuda"
    else if amdCfg.enable then
      "vulkan"
    else
      "cpu";

in
{
  imports = [
    ./colibri.nix
    ./llama-swap.nix
  ];

  options.khanelinix.services.llm = {
    enable = lib.mkEnableOption "local large language model serving" // {
      description = ''
        Enable local llama.cpp tooling and optional llama-swap/Colibri serving.

        Downloaded weights do not occupy GPU memory until loaded. Check
        residency with `ollama ps` and llama-swap's `/running` endpoint;
        use `nvtop` or `amdgpu_top` to identify competing GPU applications.
        Use the `available` column in `free -h` for system RAM headroom,
        rather than treating reclaimable filesystem cache as unavailable.

        Ollama defaults to 60 seconds idle; clients can override `keep_alive`.
        llama-swap models default to a 300-second inactivity TTL. Use
        `ollama stop MODEL` or POST to llama-swap's `/api/models/unload`
        after active requests finish to release memory without deleting weights.
        Memory release can lag the unload acknowledgement.

        See `modules/nixos/services/llm/README.md` for commands and trade-offs.
      '';
    };

    acceleration = lib.mkOption {
      type = lib.types.enum [
        "auto"
        "cpu"
        "cuda"
        "rocm"
        "vulkan"
      ];
      default = "auto";
      description = ''
        Compute backend for llama.cpp.

        "auto" picks cuda on an NVIDIA host, vulkan on an AMD host, and cpu
        elsewhere. Compare backends with the same model, quantization, context
        and speculative-decoding settings; performance varies by model and
        runtime. Ollama and llama.cpp results are not a controlled backend
        comparison unless their runner settings also match.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp.override {
        cudaSupport = resolvedAcceleration == "cuda";
        rocmSupport = resolvedAcceleration == "rocm";
        vulkanSupport = resolvedAcceleration == "vulkan";
      };
      defaultText = lib.literalExpression "pkgs.llama-cpp built for the selected acceleration";
      description = ''
        llama.cpp package that serves every model in this module.

        The override names each backend explicitly, because
        khanelinix.hardware.gpu.amd sets nixpkgs.config.rocmSupport globally and
        llama.cpp reads that flag as its own default.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # llama-bench and llama-cli measure the offload split that llama-swap then
    # serves, so keep the same build on PATH.
    environment.systemPackages = [ cfg.package ];
  };
}
