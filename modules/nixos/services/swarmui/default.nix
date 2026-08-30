{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.swarmui;

  userName = config.khanelinix.user.name;
  homeCfg = config.home-manager.users.${userName} or { };

  picturesDir =
    if homeCfg.xdg.userDirs.enable or false then
      homeCfg.xdg.userDirs.pictures
    else
      "${config.users.users.${userName}.home}/Pictures";

  comfyuiEnabled = config.khanelinix.services.comfyui.enable;
  comfyuiModels = config.khanelinix.services.comfyui.models;
  comfyuiModelRoot = pkgs.linkFarm "comfyui-models" comfyuiModels;
  comfyuiUrl = lib.removeSuffix "/" cfg.comfyuiUrl;
  modelNames = builtins.attrNames comfyuiModels;
  outputPath = if cfg.outputDir == null then "Output" else toString cfg.outputDir;

  hasModelDir = dir: lib.any (lib.hasPrefix "${dir}/") modelNames;
  modelFolders =
    defaults: dirs:
    lib.concatStringsSep ";" (defaults ++ map (dir: "khanelinix/${dir}") (lib.filter hasModelDir dirs));
  manageModelPath = field: dir: ''
    sed -i \
      -e '/^[[:space:]]*${field}:/ s#;khanelinix/${dir}\(;\|$\)#\1#g' \
      Data/Settings.fds
    ${lib.optionalString (hasModelDir dir) ''
      sed -i \
        -e '/^[[:space:]]*${field}:/ s|$|;khanelinix/${dir}|' \
        Data/Settings.fds
    ''}
  '';
  manageOutputPath = ''
    sed -i \
      -e ${lib.escapeShellArg "/^[[:space:]]*OutputPath:/d"} \
      Data/Settings.fds
    if grep -q '^[[:space:]]*Paths:' Data/Settings.fds; then
      sed -i \
        -e ${lib.escapeShellArg "/^[[:space:]]*Paths:/a\\    OutputPath: ${outputPath}"} \
        Data/Settings.fds
    elif grep -q '^[[:space:]]*Maintenance:' Data/Settings.fds; then
      sed -i \
        -e ${lib.escapeShellArg "/^[[:space:]]*Maintenance:/i\\Paths:\n    OutputPath: ${outputPath}"} \
        Data/Settings.fds
    else
      printf '%s\n' \
        'Paths:' \
        ${lib.escapeShellArg "    OutputPath: ${outputPath}"} \
        >>Data/Settings.fds
    fi
  '';

  runtimeName = baseNameOf cfg.package;
  runtimeDir = "/var/lib/swarmui/${runtimeName}";

  swarmuiLauncher = pkgs.writeShellApplication {
    name = "swarmui-service";
    text = ''
      cd ${lib.escapeShellArg runtimeDir}
      exec ${lib.getExe cfg.package} "$@"
    '';
  };

  initialModelSettings = lib.optionalString comfyuiEnabled (
    lib.concatStringsSep "\n" [
      "    SDModelFolder: ${modelFolders [ "Stable-Diffusion" ] [ "checkpoints" "diffusion_models" ]}"
      "    SDLoraFolder: ${modelFolders [ "Lora" ] [ "loras" ]}"
      "    SDVAEFolder: ${modelFolders [ "VAE" ] [ "vae" ]}"
      "    SDClipFolder: ${modelFolders [ "text_encoders" "clip" ] [ "text_encoders" ]}"
    ]
  );

  initialSettings = pkgs.writeText "swarmui-settings.fds" ''
    IsInstalled: true
    LaunchMode: none
    Paths:
    ${initialModelSettings}
        OutputPath: ${outputPath}
    Maintenance:
        CheckForUpdates: false
  '';

  initialBackends = pkgs.writeText "swarmui-backends.fds" ''
    0:
        type: comfyui_api
        title: ComfyUI
        enabled: true
        settings:
            Address: ${comfyuiUrl}
            AllowIdle: true
            OverQueue: 1
            EnableFrontendDev: false
  '';
in
{
  options.khanelinix.services.swarmui = {
    enable = lib.mkEnableOption "SwarmUI image and video generation web interface";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.khanelinix.swarmui;
      defaultText = lib.literalExpression "pkgs.khanelinix.swarmui";
      description = "SwarmUI package to run.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address on which SwarmUI listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 7801;
      description = "Port on which SwarmUI listens.";
    };

    openFirewall = lib.mkEnableOption "the SwarmUI firewall port";

    comfyuiUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8188";
      description = ''
        Initial URL for the ComfyUI API backend.

        SwarmUI owns the backend file after the first service start. Later
        option changes do not replace edits made through the web interface.
      '';
    };

    outputDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = "${picturesDir}/swarmui";
      defaultText = lib.literalExpression ''"''${xdg.userDirs.pictures}/swarmui"'';
      example = "/srv/swarmui-output";
      description = ''
        Directory that receives generated images and video and backs SwarmUI's
        History view.

        Defaults under the desktop user's XDG pictures directory. The path is
        bind-mounted into the unit, so it still resolves under /home, where
        ProtectHome would otherwise hide it. Existing state-directory outputs
        are copied here once without overwriting destination files.

        The directory is created setgid and the service writes group-writable
        files, so members of outputGroup can manage generated media.

        null keeps the output tree inside the service state directory, which no
        desktop session can traverse.
      '';
    };

    outputGroup = lib.mkOption {
      type = lib.types.str;
      default = config.users.users.${userName}.group;
      defaultText = lib.literalExpression "config.users.users.\${khanelinix.user.name}.group";
      example = "media";
      description = ''
        Group that owns outputDir and therefore manages generated media.

        Only consulted when outputDir is set.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd = {
      tmpfiles.settings = lib.mkIf (cfg.outputDir != null) {
        "10-khanelinix-swarmui-output".${cfg.outputDir}.d = {
          user = "root";
          group = cfg.outputGroup;
          mode = "2775";
        };
      };

      services = {
        comfyui = lib.mkIf comfyuiEnabled {
          environment.PYTHONPATH = pkgs.python3Packages.makePythonPath [
            pkgs.python3Packages.dill
            pkgs.python3Packages.imageio-ffmpeg
            pkgs.python3Packages.rembg
            pkgs.python3Packages.ultralytics
          ];

          preStart = lib.mkAfter ''
            ln -sfnT \
              ${cfg.package}/share/swarmui/src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon \
              /var/lib/comfyui/custom_nodes/SwarmComfyCommon
            ln -sfnT \
              ${cfg.package}/share/swarmui/src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyExtra \
              /var/lib/comfyui/custom_nodes/SwarmComfyExtra
          '';
        };

        swarmui = {
          description = "SwarmUI image and video generation web interface";
          path = [
            pkgs.dotnetCorePackages.sdk_8_0
            pkgs.git
          ]
          ++ lib.optional comfyuiEnabled pkgs.curl;
          wantedBy = [ "multi-user.target" ];
          after = [
            "network-online.target"
          ]
          ++ lib.optional comfyuiEnabled "comfyui.service";
          wants = [
            "network-online.target"
          ]
          ++ lib.optional comfyuiEnabled "comfyui.service";

          preStart = ''
            install -d \
              .dotnet \
              .nuget/packages \
              Data \
              Models \
              Output \
              src/Extensions \
              src/bin \
              ${runtimeName}

            if [[ ! -e ${runtimeName}/.khanelinix-runtime ]]; then
              cp -r --no-preserve=mode,ownership \
                ${cfg.package}/share/swarmui/. ${runtimeName}/
              touch ${runtimeName}/.khanelinix-runtime
            fi

            if [[ ! -e src/Extensions/.khanelinix-migrated ]]; then
              for oldExtensions in Extensions *-swarmui-*/src/Extensions; do
                if [[ -d "$oldExtensions" && ! -L "$oldExtensions" ]]; then
                  cp -rn --no-preserve=mode,ownership "$oldExtensions"/. src/Extensions/
                fi
              done
              touch src/Extensions/.khanelinix-migrated
            fi

            install -d ${runtimeName}/src/bin
            for sourceFile in \
              GlobalSuppressions.cs \
              GlobalUsings.cs \
              SwarmUI.deps.props \
              SwarmUI.extension.props; do
              ln -sfnT \
                ${cfg.package}/share/swarmui/src/"$sourceFile" \
                src/"$sourceFile"
            done
            ln -sfnT ${cfg.package}/lib/swarmui src/bin/live_release
            ln -sfnT \
              ${cfg.package}/lib/swarmui \
              ${runtimeName}/src/bin/live_release
            ln -sfnT ../../src/Extensions ${runtimeName}/src/Extensions
            ln -sfnT ../Models ${runtimeName}/Models
            ln -sfnT ../Output ${runtimeName}/Output
            ${lib.optionalString comfyuiEnabled ''
              # Keep the settings path stable when the declarative model set changes.
              ln -sfnT ${comfyuiModelRoot} Models/khanelinix
            ''}

            if [[ ! -e Data/Settings.fds ]]; then
              install -m 0640 ${initialSettings} Data/Settings.fds
            fi

            ${lib.optionalString (cfg.outputDir != null) ''
              if [[ ! -e Data/.khanelinix-output-migrated-v1 ]]; then
                outputDir=${lib.escapeShellArg (toString cfg.outputDir)}
                migrationList=$(mktemp Data/.output-migration.XXXXXX)
                trap 'rm -f -- "$migrationList"' EXIT
                find Output -mindepth 1 -print0 >"$migrationList"

                while IFS= read -r -d $'\0' sourcePath; do
                  relativePath="''${sourcePath#Output/}"
                  destinationPath="$outputDir/$relativePath"
                  destinationParent="''${destinationPath%/*}"

                  if [[ ! -d "$destinationParent" || -L "$destinationParent" || ! -w "$destinationParent" ]]; then
                    continue
                  fi

                  if [[ -d "$sourcePath" && ! -L "$sourcePath" ]]; then
                    if [[ ! -e "$destinationPath" && ! -L "$destinationPath" ]]; then
                      mkdir -m 0775 -- "$destinationPath"
                    fi
                  elif [[ ! -e "$destinationPath" && ! -L "$destinationPath" ]]; then
                    cp -P --no-preserve=mode,ownership \
                      -- "$sourcePath" "$destinationPath"
                  fi
                done <"$migrationList"

                rm -f -- "$migrationList"
                trap - EXIT
                touch Data/.khanelinix-output-migrated-v1
              fi
            ''}

            # OutputPath is declarative; keep all other user-owned paths intact.
            ${manageOutputPath}

            ${lib.optionalString comfyuiEnabled ''
              # Manage only the shared suffixes and preserve all user-owned paths.
              ${manageModelPath "SDModelFolder" "checkpoints"}
              ${manageModelPath "SDModelFolder" "diffusion_models"}
              ${manageModelPath "SDLoraFolder" "loras"}
              ${manageModelPath "SDVAEFolder" "vae"}
              ${manageModelPath "SDClipFolder" "text_encoders"}

              # systemd ordering only waits for the ComfyUI process to start. Its
              # HTTP API becomes available later, after models and nodes are read.
              for attempt in {1..60}; do
                if curl \
                  --fail \
                  --silent \
                  --output /dev/null \
                  --max-time 2 \
                  ${lib.escapeShellArg "${comfyuiUrl}/object_info"}; then
                  break
                fi

                if (( attempt == 60 )); then
                  echo "ComfyUI API did not become ready at ${comfyuiUrl}" >&2
                  exit 1
                fi

                sleep 1
              done
            ''}

            if [[ ! -e Data/Backends.fds ]]; then
              install -m 0640 ${initialBackends} Data/Backends.fds
            fi
          '';

          serviceConfig = {
            Type = "exec";
            BindPaths = lib.mkIf (cfg.outputDir != null) [ cfg.outputDir ];
            ExecStart = lib.concatStringsSep " " [
              (lib.getExe swarmuiLauncher)
              "--data_dir /var/lib/swarmui/Data"
              "--settings_file /var/lib/swarmui/Data/Settings.fds"
              "--backends_file /var/lib/swarmui/Data/Backends.fds"
              "--host ${lib.escapeShellArg cfg.host}"
              "--port ${toString cfg.port}"
              "--launch_mode none"
            ];
            Environment = [
              "DOTNET_CLI_HOME=/var/lib/swarmui/.dotnet"
              "HOME=/var/lib/swarmui"
              "NUGET_PACKAGES=/var/lib/swarmui/.nuget/packages"
            ];
            WorkingDirectory = "/var/lib/swarmui";

            DynamicUser = true;
            SupplementaryGroups = lib.mkIf (cfg.outputDir != null) [ cfg.outputGroup ];
            StateDirectory = "swarmui";
            StateDirectoryMode = "0750";
            UMask = lib.mkIf (cfg.outputDir != null) "0002";

            Restart = "on-failure";
            RestartSec = "5s";

            ProtectSystem = "strict";
            ProtectHome = "tmpfs";
            PrivateTmp = true;
            NoNewPrivileges = true;
            TimeoutStartSec = "4min";
          };
        };
      };
    };
  };
}
