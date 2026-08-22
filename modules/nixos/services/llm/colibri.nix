{
  config,
  lib,
  pkgs,

  ...
}:
let

  cfg = config.khanelinix.services.llm.colibri;

in
{
  options.khanelinix.services.llm.colibri = {
    package = lib.mkOption {
      type = lib.types.package;
      default =
        if cfg.hipSupport then
          pkgs.khanelinix.colibri.override { inherit (cfg) hipSupport; }
        else
          pkgs.khanelinix.colibri;
      defaultText = lib.literalExpression "pkgs.khanelinix.colibri";
      description = ''
        colibri build that serves every entry using this engine.

        colibri streams experts from disk, so it runs a model that exceeds both
        video memory and system memory. llama.cpp needs the experts in memory
        instead.
      '';
    };

    hipSupport = lib.mkEnableOption "the colibri HIP expert tier" // {
      description = ''
        Build the GPU expert tier for AMD.

        Only the colibri and qwen36 engines gain it, because upstream builds the
        shared backend for one make target. The tier needs a local patch to the
        upstream architecture gate, and it stays unverified on hardware until a
        qwen36 or GLM container runs on this host, so it defaults off.
      '';
    };
  };

  config = lib.mkIf (config.khanelinix.services.llm.enable && cfg.hipSupport) {
    assertions = [
      {
        assertion = config.khanelinix.hardware.gpu.amd.enable;
        message = "khanelinix.services.llm.colibri.hipSupport targets an AMD GPU, so khanelinix.hardware.gpu.amd must be enabled.";
      }
    ];
  };
}
