{
  pkgs,

  lib,
  config,
  ...
}:
let
  inherit (lib)
    getExe'
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    types
    ;

  json = pkgs.formats.json { };

  cfg = config.khanelinix.services.rnnoise;
  echoCancelSourceNode = "effect_output.echo-cancel";
  rnnoiseCaptureNode =
    if cfg.captureNode != null then
      cfg.captureNode
    else if cfg.echoCancel.enable then
      echoCancelSourceNode
    else
      null;

  mkTargetProps =
    target:
    optionalAttrs (target != null) {
      "target.object" = target;
      "node.dont-reconnect" = true;
    };
in
{
  options = {
    khanelinix.services.rnnoise = {
      enable = mkEnableOption "rnnoise pipewire module";

      captureNode = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional PipeWire source node to feed into the RNNoise filter.

          List source node names with `pactl list sources short` or
          `wpctl status`, then use the stable `alsa_input.*` or virtual
          `effect_output.*` node name. Avoid `*.monitor` sources unless the
          intent is to capture speaker output.
        '';
      };

      echoCancel = {
        enable = mkEnableOption "WebRTC echo cancellation before the RNNoise filter";

        captureNode = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Physical PipeWire source node to feed into the echo canceller.

            List source node names with `pactl list sources short` or
            `wpctl status`, then use the stable `alsa_input.*` node for the
            microphone that should be echo-cancelled. Do not use a
            `*.monitor` source here; monitor sources capture playback audio and
            can reintroduce echo.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.echoCancel.enable || cfg.echoCancel.captureNode != null;
        message = "khanelinix.services.rnnoise.echoCancel.captureNode must be set when echo cancellation is enabled.";
      }
    ];

    xdg.configFile."pipewire/pipewire.conf.d/99-echo-cancel.conf" = mkIf cfg.echoCancel.enable {
      source = json.generate "99-echo-cancel.conf" {
        "context.modules" = [
          {
            "name" = "libpipewire-module-echo-cancel";
            "args" = {
              "library.name" = "aec/libspa-aec-webrtc";
              "monitor.mode" = true;
              "audio.position" = [
                "FL"
                "FR"
              ];
              "capture.props" = {
                "node.name" = "effect_input.echo-cancel";
                "node.passive" = true;
              }
              // mkTargetProps cfg.echoCancel.captureNode;
              "source.props" = {
                "node.name" = echoCancelSourceNode;
                "node.description" = "Echo Canceling source";
                "media.class" = "Audio/Source";
                "device.string" = echoCancelSourceNode;
                "device.bus" = "virtual";
              };
              "playback.props" = {
                "node.name" = "effect_playback.echo-cancel";
                "node.passive" = true;
              };
            };
          }
        ];
      };
    };

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
              }
              // mkTargetProps rnnoiseCaptureNode;
              "playback.props" = {
                "node.name" = "effect_output.rnnoise";
                "media.class" = "Audio/Source";
                # Citrix needs stable source metadata to derive a device/group ID.
                "device.string" = "effect_output.rnnoise";
                "device.bus" = "virtual";
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
