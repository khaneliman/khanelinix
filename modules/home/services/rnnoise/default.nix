{
  pkgs,

  lib,
  config,
  ...
}:
let
  inherit (lib) getExe' mkEnableOption mkIf;

  json = pkgs.formats.json { };

  cfg = config.khanelinix.services.rnnoise;
in
{
  options = {
    khanelinix.services.rnnoise = {
      enable = mkEnableOption "rnnoise pipewire module";
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."pipewire/filter-chain.conf.d/99-input-denoising.conf" = {
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
                    "plugin" = "librnnoise_ladspa";
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

    systemd.user.services.rnnoise-filter-chain = {
      Unit = {
        Description = "PipeWire filter chain daemon";
        After = [
          "pipewire.service"
          "pipewire-session-manager.service"
        ];
        BindsTo = [ "pipewire.service" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${getExe' pkgs.pipewire "pipewire"} -c filter-chain.conf";
        Environment = "LADSPA_PATH=${pkgs.rnnoise-plugin}/lib/ladspa";
        Restart = "on-failure";
        Slice = "session.slice";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
