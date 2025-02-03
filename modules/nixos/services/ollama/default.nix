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

      environmentVariables = {
        HCC_AMDGPU_TARGET = lib.mkIf (amdCfg.enable && amdCfg.enableRocmSupport) "gfx1102";
      };
    };
  };
}
