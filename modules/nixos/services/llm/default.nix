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
    ./llama-swap.nix
  ];

  options.khanelinix.services.llm = {
    enable = lib.mkEnableOption "local large language model serving";

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
        elsewhere. Vulkan serves RDNA3 consumer cards at least as well as rocm,
        and the binary cache carries both variants.
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
