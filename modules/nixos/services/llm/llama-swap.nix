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

  # ollama keeps its store under /var/lib/private, which only root may traverse,
  # and /var/lib/ollama is a symlink into that directory. Binding onto the
  # symlink resolves back to the unreachable path, so the service reads the
  # store through a mount point of its own.
  modelsRoot = "/var/lib/llm/ollama-models";

  # colibri containers belong outside /home, which the unit hides.
  colibriRoot = "/var/lib/llm/colibri";

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

      manifest="${modelsRoot}/manifests/registry.ollama.ai/library/$name/$ref"
      if [ ! -f "$manifest" ]; then
        echo "no ollama manifest for $tag at $manifest" >&2
        exit 1
      fi

      digest="$(jq -r '.layers[] | select(.mediaType == "application/vnd.ollama.image.model") | .digest' "$manifest")"
      if [ -z "$digest" ] || [ "$digest" = "null" ]; then
        echo "manifest for $tag carries no model layer" >&2
        exit 1
      fi

      exec llama-server --model "${modelsRoot}/blobs/''${digest/:/-}" "$@"
    '';
  };

  colibriCfg = cfg.colibri;

  # colibri owns its own model container and reads experts from disk, so it
  # takes a directory rather than a resolved blob.
  mkColibriCmd =
    name: model:
    lib.concatStringsSep " " (
      [
        "${lib.getExe colibriCfg.package} serve"
        "--model ${model.modelDir}"
        "--host 127.0.0.1"
        "--port \${PORT}"
        # llama-swap forwards the requested name upstream, and colibri rejects a
        # name it does not advertise, so the engine answers to its entry key.
        "--model-id ${name}"
      ]
      ++ lib.optional (model.contextSize != null) "--ctx ${toString model.contextSize}"
      ++ model.extraArgs
    );

  # llama-swap splits this string into arguments itself, so keep it on one line
  # rather than using shell continuations.
  mkLlamaCmd =
    model:
    lib.concatStringsSep " " (
      [
        "${lib.getExe serve} ${model.tag}"
        "--host 127.0.0.1"
        # llama-swap assigns the upstream port through this macro.
        "--port \${PORT}"
        "--parallel ${toString model.parallelSlots}"
      ]
      ++ lib.optional (model.contextSize != null) "--ctx-size ${toString model.contextSize}"
      ++ lib.optional (model.cpuMoeLayers != null) "--n-cpu-moe ${toString model.cpuMoeLayers}"
      ++ lib.optionals (model.kvCacheType != "f16") [
        # Quantized cache entries need flash attention.
        "--flash-attn on"
        "--cache-type-k ${model.kvCacheType}"
        "--cache-type-v ${model.kvCacheType}"
      ]
      ++ model.extraArgs
    );

  settingsFormat = pkgs.formats.yaml { };

  configFile = settingsFormat.generate "llama-swap.yaml" {
    inherit (swapCfg) healthCheckTimeout;

    logLevel = "info";

    # Without upstream output, a model that fails to load reports only that its
    # command exited.
    logToStdout = "both";

    models = lib.mapAttrs (name: model: {
      cmd = if model.backend == "colibri" then mkColibriCmd name model else mkLlamaCmd model;
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
            backend = lib.mkOption {
              type = lib.types.enum [
                "colibri"
                "llama-cpp"
              ];
              default = "llama-cpp";
              description = ''
                Engine serving this entry.

                llama-cpp loads a GGUF from the ollama store and needs the
                weights to fit memory. colibri reads its own container and
                streams experts from disk, which runs a model that fits
                neither video memory nor system memory.
              '';
            };

            tag = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "qwen3-coder:30b";
              description = "ollama tag holding the GGUF, for the llama-cpp backend.";
            };

            modelDir = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = "/var/lib/llm/colibri/qwen36";
              description = "colibri container directory, for the colibri backend.";
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

            parallelSlots = lib.mkOption {
              type = lib.types.ints.positive;
              default = 1;
              description = ''
                Number of request slots the server allocates.

                Each slot reserves its own share of the context, so more slots
                shrink the memory left for weights. One slot measured 154
                tokens per second against 137 for the upstream default of four,
                and llama-swap serves one model at a time anyway.
              '';
            };

            kvCacheType = lib.mkOption {
              type = lib.types.enum [
                "f16"
                "q4_0"
                "q8_0"
              ];
              default = "q8_0";
              description = ''
                Precision of the key and value cache.

                A quantized cache leaves more memory for weights, so more layers
                reach the GPU. On a 24 GiB card with a 30B mixture-of-experts
                model at 32768 context, q8_0 measured 177 tokens per second
                against 154 for f16, and freed 1.3 GiB.
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
    ]
    ++ lib.mapAttrsToList (name: model: {
      assertion = if model.backend == "colibri" then model.modelDir != null else model.tag != null;
      message = "khanelinix.services.llm.llamaSwap.models.${name} needs ${
        if model.backend == "colibri" then "modelDir" else "tag"
      } for the ${model.backend} backend.";
    }) swapCfg.models
    ++ lib.mapAttrsToList (name: model: {
      # These render llama-server flags, so a colibri entry would drop them.
      assertion =
        model.backend == "llama-cpp" || (model.cpuMoeLayers == null && model.kvCacheType == "q8_0");
      message = "khanelinix.services.llm.llamaSwap.models.${name} sets llama.cpp cache options that the colibri backend ignores.";
    }) swapCfg.models
    ++ lib.mapAttrsToList (name: model: {
      # The unit sets ProtectHome, so a container under /home is invisible to it.
      assertion = model.backend != "colibri" || !(lib.hasPrefix "/home/" (toString model.modelDir));
      message = "khanelinix.services.llm.llamaSwap.models.${name} keeps its container under /home, which the service cannot read. Use ${colibriRoot} instead.";
    }) swapCfg.models;

    networking.firewall.allowedTCPPorts = lib.mkIf swapCfg.openFirewall [ swapCfg.port ];

    systemd.tmpfiles.rules = [
      "d /var/lib/llm 0750 ${ollamaCfg.user} ${ollamaCfg.group} -"
      "d ${modelsRoot} 0750 ${ollamaCfg.user} ${ollamaCfg.group} -"
      "d ${colibriRoot} 0750 ${ollamaCfg.user} ${ollamaCfg.group} -"
    ];

    systemd.services.llama-swap = {
      description = "Model swapping proxy for llama.cpp";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "ollama.service"
      ];

      environment.XDG_CACHE_HOME = "/var/cache/llm";

      serviceConfig = {
        Type = "exec";
        ExecStart = "${lib.getExe pkgs.llama-swap} --config ${configFile} --listen 127.0.0.1:${toString swapCfg.port}";
        Restart = "on-failure";

        # Sharing ollama's identity grants read access to blobs the ollama user
        # owns, without loosening their permissions.
        User = ollamaCfg.user;
        Group = ollamaCfg.group;

        # systemd mounts this before dropping privileges, so the service reads
        # the store without traversing /var/lib/private.
        BindReadOnlyPaths = [
          "/var/lib/private/ollama/models:${modelsRoot}"
        ];

        # llama-server needs the render node for every backend except cpu.
        # "char-drm" names the device subsystem: a directory path is not a valid
        # device rule, and any DeviceAllow entry closes the default policy, so
        # naming /dev/dri here would block every node and drop the GPU.
        SupplementaryGroups = [
          "render"
          "video"
        ];
        DeviceAllow = [ "char-drm rw" ];

        # Mesa writes its shader cache under XDG_CACHE_HOME and disables the
        # cache when that path is read-only, which recompiles pipelines on each
        # start.
        CacheDirectory = "llm";

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
