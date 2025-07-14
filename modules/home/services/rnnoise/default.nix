{
  pkgs,

  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption;

  json = pkgs.formats.json { };

  cfg = config.khanelinix.services.rnnoise;
in
{
  options = {
    khanelinix.services.rnnoise = {
      enable = mkEnableOption "rnnoise pipewire module";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."pipewire/pipewire.conf.d/99-input-denoising.conf" = {
      source = json.generate "99-input-denoising.conf" {
        "context.modules" = [
          {
            "name" = "libpipewire-module-filter-chain";
            "args" = {
              "node.description" = "Noise Canceling source";
              "media.name" = "Noise Canceling source";
              "filter.graph" = {
                "nodes" = [
                  {
                    "type" = "ladspa";
                    "name" = "rnnoise";
                    "plugin" = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                    "label" = "noise_suppressor_stereo";
                    "control" = {
                      "VAD Threshold (%)" = 70.0;
                    };
                  }
                ];
              };
              "audio.position" = [
                "FL"
                "FR"
              ];
              "capture.props" = {
                "node.name" = "effect_input.rnnoise";
                "node.passive" = true;
              };
              "playback.props" = {
                "node.name" = "effect_output.rnnoise";
                "media.class" = "Audio/Source";
              };
            };
          }
        ];
      };
    };
  };
}
