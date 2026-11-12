{
  config,
  lib,
  osConfig ? { },
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.t3code;
  t3codePatches = import ./patches.nix;
in
{
  options.khanelinix.programs.terminal.tools.t3code.enable =
    lib.mkEnableOption "T3 Code configuration";

  config =
    let
      tailscaleEnabled =
        (osConfig.khanelinix.services.tailscale.enable or false)
        || (osConfig.services.tailscale.enable or false)
        || (config.khanelinix.services.tailscale.enable or false);

      claudeCodeEnabled = config.programs.claude-code.enable or false;
      claudeProviderSettings = {
        binaryPath = lib.getExe config.programs.claude-code.package;
        homePath = config.programs.claude-code.configDir;
      };

      githubRoot = "${config.home.homeDirectory}/${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Documents/"}github";

      worktreeIdleDays = 3;

      overrideT3codeSource =
        package:
        let
          pnpm =
            if pkgs.stdenv.hostPlatform.isDarwin then
              pkgs.pnpm_12.override { nodejs-slim = pkgs.nodejs-slim_24; }
            else
              pkgs.pnpm_12;
          t3codeArgs = builtins.functionArgs (import "${pkgs.path}/pkgs/by-name/t3/t3code/unwrapped.nix");
          pnpmArg =
            lib.findFirst (name: t3codeArgs ? ${name})
              (throw "t3code package exposes none of pnpm_10, pnpm_11, or pnpm_12")
              [
                "pnpm_12"
                "pnpm_11"
                "pnpm_10"
              ];
        in
        (package.override { ${pnpmArg} = pnpm; }).overrideAttrs (
          old:
          let
            t3codeVersion =
              (builtins.fromJSON (builtins.readFile (inputs.t3code + "/apps/desktop/package.json"))).version;
          in
          {
            src = inputs.t3code // {
              name = "source";
            };
            version = t3codeVersion;
            patches = (old.patches or [ ]) ++ t3codePatches;
            nativeBuildInputs =
              (old.nativeBuildInputs or [ ])
              ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.pkg-config ];
            buildInputs =
              (old.buildInputs or [ ]) ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libsecret ];
            postPatch = ''
              substituteInPlace apps/web/vite.config.ts \
                --replace-fail 'const host = explicitHost || "localhost";' \
                               'const host = explicitHost || "127.0.0.1";'
            '';
            pnpmDeps = pkgs.fetchPnpmDeps {
              inherit (old) pname pnpmWorkspaces;
              version = t3codeVersion;
              src = inputs.t3code;
              inherit pnpm;
              fetcherVersion = 5;
              # Large platform binaries (rolldown, esbuild) trip pnpm's 60s
              # default fetch timeout on slow links; the fetch env doesn't
              # affect the fixed-output hash.
              prePnpmInstall = ''
                pnpm config set fetch-timeout 600000
                pnpm config set fetch-retries 5
                pnpm config set network-concurrency 8
              '';
              hash = "sha256-fva/uR5cAoJn/vAtL2t2jP2QxyzjpQag/oQh34akIhY=";
            };
            # License generation otherwise downloads SPDX notices during the sandboxed build.
            preBuild = ''
              mkdir -p .generated/third-party-licenses/spdx
              cp -r ${pkgs.spdx-license-list-data.json}/json/details \
                .generated/third-party-licenses/spdx/v${pkgs.spdx-license-list-data.version}
            ''
            + (old.preBuild or "");
            postBuild = (old.postBuild or "") + ''
              ${lib.getExe pkgs.nodejs} ${./prune-node-modules.mjs} "$PWD"
            '';
            # Runtime dependencies contain prebuilt native artifacts. Scanning
            # the JavaScript-heavy closure with Darwin strip costs minutes.
            dontStrip = true;
          }
        );

      t3codePackage =
        let
          overrides = {
            inherit (pkgs) gh;
            inherit (pkgs) git;

            enableClaude = false;
            enableCodex = false;
            enableGit = true;
            enableGitHub = true;
            enableJujutsu = false;
            enableOpencode = false;
          };
        in
        if pkgs.t3code ? unwrapped then
          pkgs.t3code.override (
            overrides
            // {
              t3code-unwrapped = overrideT3codeSource pkgs.t3code.unwrapped;
            }
          )
        else
          overrideT3codeSource (pkgs.t3code.override overrides);

      syncProviderSettings = pkgs.writeShellApplication {
        name = "t3code-sync-provider-settings";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
          settingsPath="$1"
          if [ ! -f "$settingsPath" ]; then
            exit 0
          fi

          temporaryPath=$(mktemp "$settingsPath.XXXXXX")
          trap 'rm -f "$temporaryPath"' EXIT
          jq --slurpfile managed ${
            (pkgs.formats.json { }).generate "t3code-managed-providers.json"
              config.programs.t3code.userSettings.providers
          } \
            -f ${./sync-provider-settings.jq} "$settingsPath" > "$temporaryPath"
          if ! cmp -s "$settingsPath" "$temporaryPath"; then
            mv "$temporaryPath" "$settingsPath"
          fi
        '';
      };

      # Upstream renumbers inline sqlite migrations between revisions while the
      # server only tracks applied migrations by id, so an existing database
      # skips renumbered migrations and crashes on missing columns. Reconcile
      # recorded history by name for manual recovery of legacy state.sqlite.
      reconcileCommand = pkgs.writeShellApplication {
        name = "t3code-reconcile-migrations";
        runtimeInputs = [ pkgs.nodejs ];
        text = ''
          exec node ${./reconcile-migrations.mjs} \
            ${t3codePackage}/libexec/t3code/apps/server/dist/bin.mjs \
            "$HOME/.t3/userdata/state.sqlite"
        '';
      };

      # Mint a tailnet pairing link on this host or, given an SSH host, on that
      # host's backend. Usage: t3-pair [ssh-host] [t3 pair flags...]
      pairCommand = pkgs.writeShellApplication {
        name = "t3-pair";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          label=$(uname -n)
          label=''${label%%.*}

          # t3 keeps the first --label, so caller flags override this default.
          if [ "$#" -gt 0 ] && [ "''${1#-}" = "$1" ]; then
            host=$1
            shift
            # ssh joins arguments into one remote shell command, so quote them.
            exec ssh "$host" t3 pair --tailscale "''${@@Q}" --label "''${label@Q}"
          fi

          exec t3 pair --tailscale "$@" --label "$label"
        '';
      };

      # Linux only: the in-use check reads process working directories from /proc.
      storageGcCommand = pkgs.writeShellApplication {
        name = "t3code-storage-gc";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gawk
          pkgs.git
          pkgs.sqlite
          pkgs.util-linux
        ];
        # Prepend the defaults so `t3code-storage-gc --dry-run` previews a run.
        text = ''
          set -- ${
            lib.escapeShellArgs [
              "--t3-home"
              "${config.home.homeDirectory}/.t3"
              "--idle-days"
              (toString worktreeIdleDays)
              "--max-new-file-mib"
              "50"
              "--folder-days"
              "14"
              "--cache-hours"
              "24"
            ]
          } "$@"
        ''
        + builtins.readFile ./storage-gc.sh;
      };
    in
    lib.mkIf cfg.enable {
      home = {
        packages = [
          reconcileCommand
        ]
        ++ lib.optional tailscaleEnabled pairCommand
        ++ lib.optional pkgs.stdenv.hostPlatform.isLinux storageGcCommand;

        # A paired client must not start a second writer for the service's state.
        activation.t3codeDesktopSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "{}";
            jqOperation = "$dynamic * $static";
            path = "${config.home.homeDirectory}/.t3/userdata/desktop-settings.json";
            mode = "600";
            reader = "${lib.getExe (pkgs.python3Packages.toPythonApplication pkgs.python3Packages.json5)} --as-json";
            staticSettings = (pkgs.formats.json { }).generate "t3code-desktop-settings" {
              localEnvironmentEnabled = false;
            };
          }
        );

        # Explicit instances shadow legacy providers. Update only Nix-owned
        # fields without creating instances or overriding undeclared GUI enablement.
        activation.t3codeProviderSettings = lib.hm.dag.entryAfter [ "t3codeSettingsActivation" ] ''
          run ${lib.getExe syncProviderSettings} ${lib.escapeShellArg "${config.home.homeDirectory}/.t3/userdata/settings.json"}
        '';

        # Uses the logged-in desktop's keyring over SSH, without screen controls.
        # Usage from another machine: ssh khanelinix t3-repair khanelimac.
        file.".local/bin/t3-repair" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          source = lib.getExe (pkgs.callPackage ./repair-connection.nix { });
        };
      };

      systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        services = {
          t3code.Service.Environment = lib.optional tailscaleEnabled
            "PATH=${lib.makeBinPath [ pkgs.tailscale ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin";

          t3code-storage-gc = {
            Unit.Description = "Reclaim storage left by T3 agent runs";
            Service = {
              Type = "oneshot";
              ExecStart = lib.getExe storageGcCommand;
              Nice = 19;
              IOSchedulingClass = "idle";
            };
          };
        };

        timers.t3code-storage-gc = {
          Unit.Description = "Reclaim storage left by T3 agent runs hourly";
          Timer = {
            OnCalendar = "hourly";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };

      launchd.agents.t3code = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        config = {
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/t3code.out.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/t3code.err.log";
          EnvironmentVariables = {
            PATH = "/Applications/Tailscale.app/Contents/MacOS:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };
      };

      programs.t3code = {
        enable = true;
        package = t3codePackage;
        mutableClientSettings = true;

        server = {
          enable = true;
          extraArgs = [
            "--host"
            "127.0.0.1"
            "--port"
            "3773"
          ]
          ++ lib.optional tailscaleEnabled "--tailscale-serve"
          ++ [ githubRoot ];

          # Paired desktop clients run no local server, so this covers analytics.
          environmentFile = pkgs.writeText "t3code-server.env" ''
            T3CODE_TELEMETRY_ENABLED=false
          '';
        };

        userSettings = {
          addProjectBaseDirectory = githubRoot;
          # Nix owns every provider binary, so upstream version advisories are
          # never actionable. This also gates the remote model-manifest fetch,
          # so new model ids arrive with package updates instead.
          enableProviderUpdateChecks = false;
          snoozeLimitedThreads = true;
          autoResumeLimitedThreads = true;
          branchNamingMode = "semantic";
          removeAgentCreditsOnMerge = true;
          # The hourly sweep keeps each branch and recreates the checkout when
          # its thread resumes. Keep the default keep rule: "tracked-changes"
          # runs `git clean -ffdx` and deletes untracked files before removal.
          storageCleanup = {
            worktreeAfterDays = worktreeIdleDays;
            worktreeSettledAfterDays = 0;
            worktreeOnDelete = true;
            worktreeOnMerge = true;
            browserArtifactsAfterDays = 14;
            logsAfterDays = 14;
          };
          # Keep threads until their PR merges or they are settled manually.
          sidebarAutoSettleAfterDays = null;

          linkedEnvironmentsEnabled = true;
          promptSuggestionsEnabled = true;
          reviewGuidesEnabled = true;
          fastWorktreeCheckout = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin true;

          defaultModelSelection = lib.mkIf claudeCodeEnabled {
            instanceId = "claudeAgent";
            model = "claude-opus-5-5";
          };
          # The server owns model favorites. Clients copy their local list to
          # it once and ignore client-settings.json afterward. The activation
          # merge replaces arrays, so this list overwrites GUI edits.
          favorites = [
            {
              provider = "claudeAgent";
              model = "claude-fable-5-2";
            }
            {
              provider = "claudeAgent";
              model = "claude-opus-5-5";
            }
            {
              provider = "codex";
              model = "gpt-6-astra";
            }
            {
              provider = "codex";
              model = "gpt-6.1-sol";
            }
            {
              provider = "codex";
              model = "gpt-6-luna";
            }
            {
              provider = "antigravity";
              model = "gemini-4-argon-medium";
            }
          ];

          providers =
            lib.optionalAttrs (config.programs.codex.enable or false) {
              codex = {
                # Existing native model IDs and histories must not switch accounts.
                binaryPath = lib.getExe (
                  config.programs.codex.package.direct or config.programs.codex.package
                );
                homePath =
                  config.home.sessionVariables.CODEX_HOME or "${config.home.homeDirectory}/.codex";
              };
            }
            // lib.optionalAttrs claudeCodeEnabled {
              claudeAgent = claudeProviderSettings;
            }
            // lib.optionalAttrs (config.programs.opencode.enable or false) {
              # The provider defaults to disabled upstream, so a binary path
              # alone leaves it off.
              opencode = {
                enabled = true;
                binaryPath = lib.getExe config.programs.opencode.package;
              };
            }
            // {
              antigravity = {
                enabled = true;
                binaryPath = lib.getExe pkgs.antigravity-acp;
              };
            };

          providerInstances = lib.optionalAttrs claudeCodeEnabled {
            claudeAgent = {
              driver = "claudeAgent";
              enabled = true;
              config = {
                enabled = true;
              }
              // claudeProviderSettings;
            };
          };
        };

        # Merge declared values on activation while preserving undeclared GUI
        # settings.
        clientSettings = {
          boringSidebarEnabled = true;
          chatWidth = "wide";
          effortDisplay = "bars";
          inAppNotificationsEnabled = true;
          loadBalancingEnabled = true;
          mathRenderingEnabled = true;
          notificationMode = "notifications";
          persistComposerContextStrip = true;
          snapShotEnabled = true;
          # Context window meter in the thread details card.
          threadDetailsItems.context = true;
        };
      };
    };
}
