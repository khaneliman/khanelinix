{
  config,
  lib,
  pkgs,

  ...
}:
let

  cfg = config.khanelinix.services.llm;
  swapCfg = cfg.llamaSwap;

  ollamaCfg = config.services.ollama;

  # ollama stores a tag as a manifest that points at content-addressed blobs, so
  # the GGUF path is only known at runtime. Resolve it when the model starts.
  serve = pkgs.writeShellApplication {
    name = "khanelinix-llama-serve";

    runtimeInputs = [
      cfg.package
      pkgs.jq
    ];

    text = ''
      if [ "$#" -lt 1 ]; then
        echo "usage: khanelinix-llama-serve <ollama-tag> [llama-server args...]" >&2
        exit 2
      fi

      tag="$1"
      shift

      name="''${tag%%:*}"
      ref="''${tag##*:}"
      if [ "$name" = "$ref" ]; then
        ref="latest"
      fi

      manifest="${ollamaCfg.modelsDir}/manifests/registry.ollama.ai/library/$name/$ref"
      if [ ! -f "$manifest" ]; then
        echo "no ollama manifest for $tag at $manifest" >&2
        exit 1
      fi

      digest="$(jq -r '.layers[] | select(.mediaType == "application/vnd.ollama.image.model") | .digest' "$manifest")"
      if [ -z "$digest" ] || [ "$digest" = "null" ]; then
        echo "manifest for $tag carries no model layer" >&2
        exit 1
      fi

      exec llama-server --model "${ollamaCfg.modelsDir}/blobs/''${digest/:/-}" "$@"
    '';
  };

  # llama-swap splits this string into arguments itself, so keep it on one line
  # rather than using shell continuations.
  mkCmd =
    model:
    lib.concatStringsSep " " (
      [
        "${lib.getExe serve} ${model.tag}"
        "--host 127.0.0.1"
        # llama-swap assigns the upstream port through this macro.
        "--port \${PORT}"
      ]
      ++ lib.optional (model.contextSize != null) "--ctx-size ${toString model.contextSize}"
      ++ lib.optional (model.cpuMoeLayers != null) "--n-cpu-moe ${toString model.cpuMoeLayers}"
      ++ model.extraArgs
    );

  settingsFormat = pkgs.formats.yaml { };

  configFile = settingsFormat.generate "llama-swap.yaml" {
    inherit (swapCfg) healthCheckTimeout;

    logLevel = "info";

    # Without upstream output, a model that fails to load reports only that its
    # command exited.
    logToStdout = "both";

    models = lib.mapAttrs (_: model: {
      cmd = mkCmd model;
      inherit (model) ttl;
    }) swapCfg.models;
  };

in
{
  options.khanelinix.services.llm.llamaSwap = {
    enable = lib.mkEnableOption "llama-swap model swapping proxy";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Port serving the OpenAI-compatible API.";
    };

    openFirewall = lib.mkEnableOption "opening the llama-swap port";

    healthCheckTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 600;
      description = ''
        Seconds llama-swap waits for a model to answer its health check.

        A large mixture-of-experts model loads slowly when most experts live in
        system memory, so this exceeds the upstream default.
      '';
    };

    models = lib.mkOption {
      default = { };
      description = ''
        Models llama-swap serves, keyed by the name clients request.

        Each entry loads an existing ollama tag, so no model is downloaded
        twice.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            tag = lib.mkOption {
              type = lib.types.str;
              example = "qwen3-coder:30b";
              description = "ollama tag holding the GGUF to serve.";
            };

            contextSize = lib.mkOption {
              type = lib.types.nullOr lib.types.ints.positive;
              default = null;
              description = "Context window in tokens. Null keeps the llama.cpp default.";
            };

            cpuMoeLayers = lib.mkOption {
              type = lib.types.nullOr lib.types.ints.unsigned;
              default = null;
              example = 32;
              description = ''
                Number of layers whose mixture-of-experts tensors stay in system
                memory, passed as --n-cpu-moe.

                Experts hold most of the weights and each one runs rarely, so
                moving them off the GPU frees the most memory for the smallest
                loss. Attention still runs on the GPU every token. Lower this
                value until the GPU runs out of memory, then raise it one step,
                because throughput falls sharply past that point.

                A dense model gains nothing here, since every parameter runs on
                every token.
              '';
            };

            ttl = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 300;
              description = ''
                Seconds of inactivity before llama-swap unloads the model. Zero
                keeps it resident.
              '';
            };

            extraArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [ "--flash-attn" ];
              description = "Additional llama-server arguments.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf (cfg.enable && swapCfg.enable) {
    assertions = [
      {
        assertion = ollamaCfg.enable;
        message = "khanelinix.services.llm.llamaSwap reads ollama's model store, so ollama must be enabled.";
      }
      {
        assertion = ollamaCfg.user != null;
        message = "khanelinix.services.llm.llamaSwap shares ollama's identity, so services.ollama.user must be set.";
      }
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf swapCfg.openFirewall [ swapCfg.port ];

    systemd.services.llama-swap = {
      description = "Model swapping proxy for llama.cpp";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "ollama.service"
      ];

      serviceConfig = {
        Type = "exec";
        ExecStart = "${lib.getExe pkgs.llama-swap} --config ${configFile} --listen 127.0.0.1:${toString swapCfg.port}";
        Restart = "on-failure";

        # Sharing ollama's identity grants read access to blobs the ollama user
        # owns, without loosening their permissions.
        User = ollamaCfg.user;
        Group = ollamaCfg.group;

        # ollama keeps its state under /var/lib/private, which only root may
        # traverse. systemd mounts this before dropping privileges, so the
        # service reads the store at the path the resolver expects.
        BindReadOnlyPaths = [
          "/var/lib/private/ollama/models:${ollamaCfg.modelsDir}"
        ];

        # llama-server needs the render node for every backend except cpu.
        SupplementaryGroups = [
          "render"
          "video"
        ];
        DeviceAllow = [ "/dev/dri rw" ];

        CapabilityBoundingSet = [ "" ];
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
      };
    };
  };
}
