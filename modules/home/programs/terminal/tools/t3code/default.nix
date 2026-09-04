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
  t3codePatches = import ./patches.nix { inherit pkgs; };
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

      overrideT3codeSource =
        package:
        let
          pnpm =
            if pkgs.stdenv.hostPlatform.isDarwin then
              pkgs.pnpm_11.override { nodejs-slim = pkgs.nodejs-slim_24; }
            else
              pkgs.pnpm_11;
          t3codeArgs = builtins.functionArgs (import "${pkgs.path}/pkgs/by-name/t3/t3code/unwrapped.nix");
          pnpmOverride =
            if t3codeArgs ? pnpm_11 then
              { pnpm_11 = pnpm; }
            else if t3codeArgs ? pnpm_10 then
              { pnpm_10 = pnpm; }
            else
              throw "t3code package exposes neither pnpm_10 nor pnpm_11";
        in
        (package.override pnpmOverride).overrideAttrs (
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
              fetcherVersion = 4;
              # Large platform binaries (rolldown, esbuild) trip pnpm's 60s
              # default fetch timeout on slow links; the fetch env doesn't
              # affect the fixed-output hash.
              prePnpmInstall = ''
                pnpm config set fetch-timeout 600000
                pnpm config set fetch-retries 5
                pnpm config set network-concurrency 8
              '';
              hash = "sha256-mgRMeBpJmiTat38APyE4guNJ+6RiQhenphP7tRcmc+k=";
            };
            postBuild = (old.postBuild or "") + ''
              ${lib.getExe pkgs.nodejs} ${./prune-node-modules.mjs} "$PWD"
            '';
            postInstall = (old.postInstall or "") + ''
              wrapProgram "$out/bin/t3code-desktop" \
                --set T3CODE_DESKTOP_ATTACH_EXISTING 1 \
                --set T3CODE_PORT 3773
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
      # recorded history by name against the installed bundle before launch.
      reconcileCommand = pkgs.writeShellApplication {
        name = "t3code-reconcile-migrations";
        runtimeInputs = [ pkgs.nodejs ];
        text = ''
          exec node ${./reconcile-migrations.mjs} \
            ${t3codePackage}/libexec/t3code/apps/server/dist/bin.mjs \
            "$HOME/.t3/userdata/state.sqlite"
        '';
      };

      remoteCommand =
        let
          claudeCodePackage = config.programs.claude-code.package or null;
        in
        pkgs.writeShellApplication {
          name = "t3code-remote";
          runtimeInputs = [
            t3codePackage
            pkgs.coreutils
          ]
          ++ lib.optionals (tailscaleEnabled && pkgs.stdenv.hostPlatform.isLinux) [ pkgs.tailscale ]
          ++ lib.optional (claudeCodePackage != null) claudeCodePackage;
          text = ''
            ${lib.optionalString tailscaleEnabled ''
              export PATH="/Applications/Tailscale.app/Contents/MacOS:/opt/homebrew/bin:/usr/local/bin:$PATH"

              if command -v tailscale >/dev/null 2>&1; then
                for _ in $(seq 1 30); do
                  if tailscale status --json >/dev/null 2>&1; then
                    break
                  fi
                  sleep 2
                done
              fi
            ''}

            ${lib.getExe reconcileCommand}

            exec ${lib.getExe' t3codePackage "t3"} ${
              lib.escapeShellArgs (
                [
                  "serve"
                  "--host"
                  "127.0.0.1"
                  "--port"
                  "3773"
                ]
                ++ lib.optional tailscaleEnabled "--tailscale-serve"
                ++ [ githubRoot ]
              )
            }
          '';
        };
    in
    lib.mkIf cfg.enable {
      home = {
        packages = [ reconcileCommand ];

        # Explicit instances shadow legacy providers. Update only Nix-owned
        # fields without creating instances or overriding undeclared GUI enablement.
        activation.t3codeProviderSettings = lib.hm.dag.entryAfter [ "t3codeSettingsActivation" ] ''
          run ${lib.getExe syncProviderSettings} ${lib.escapeShellArg "${config.home.homeDirectory}/.t3/userdata/settings.json"}
        '';

        shellAliases.t3-remote = lib.mkIf tailscaleEnabled (lib.getExe remoteCommand);
      };

      systemd.user.services.t3code-remote = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        Unit = {
          Description = "T3 Code canonical backend";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Service = {
          ExecStart = lib.getExe remoteCommand;
          Restart = "on-failure";
          RestartSec = "10s";
        };

        Install.WantedBy = [ "default.target" ];
      };

      launchd.agents.t3code-remote = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        enable = true;
        config = {
          ProgramArguments = [ (lib.getExe remoteCommand) ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/t3code-remote.out.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/t3code-remote.err.log";
          EnvironmentVariables = {
            PATH = "/Applications/Tailscale.app/Contents/MacOS:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };
      };

      programs.t3code = {
        enable = true;
        package = t3codePackage;
        mutableClientSettings = true;

        userSettings = {
          addProjectBaseDirectory = githubRoot;
          sidebarAutoSettleAfterDays = 3;
          textGenerationModelSelection = {
            instanceId = "codex";
            model = "gpt-5.6-luna";
            options = [
              {
                id = "reasoningEffort";
                value = "low";
              }
            ];
          };

          providers =
            lib.optionalAttrs (config.programs.codex.enable or false) {
              codex.binaryPath = lib.getExe config.programs.codex.package;
            }
            // lib.optionalAttrs claudeCodeEnabled {
              claudeAgent = claudeProviderSettings;
            }
            // lib.optionalAttrs (config.programs.opencode.enable or false) {
              opencode.binaryPath = lib.getExe config.programs.opencode.package;
            }
            // {
              antigravity = {
                enabled = true;
                binaryPath = lib.getExe pkgs.khanelinix.antigravity-acp;
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
        # settings. Declared arrays, including favorites, replace GUI values.
        clientSettings = {
          confirmThreadArchive = false;
          confirmThreadDelete = true;
          diffIgnoreWhitespace = true;
          environmentIdentificationMode = "artwork";
          favorites = [
            {
              provider = "claudeAgent";
              model = "claude-fable-5-1";
            }
            {
              provider = "claudeAgent";
              model = "claude-opus-5";
            }
            {
              provider = "codex";
              model = "gpt-6-astra";
            }
            {
              provider = "codex";
              model = "gpt-5.6-sol";
            }
            {
              provider = "codex";
              model = "gpt-5.6-luna";
            }
            {
              provider = "codex";
              model = "gpt-5.3-codex-spark";
            }
            {
              provider = "antigravity";
              model = "gemini-3.8-flash-medium";
            }
          ];
          fontFamilyCode = "";
          fontFamilyComposer = "";
          fontFamilySans = "";
          fontFamilyTerminal = "";
          fontSizeCode = 13;
          fontSizeInterface = 16;
          fontSizePrompt = 14;
          fontSizeTerminal = 12;
          fontSmoothing = true;
          glassOpacity = 80;
          legacySidebarEnabled = false;
          planModeEnabled = false;
          providerModelPreferences = { };
          sidebarProjectGroupingMode = "repository";
          sidebarProjectSortOrder = "updated_at";
          sidebarThreadPreviewCount = 6;
          sidebarThreadSortOrder = "updated_at";
          timestampFormat = "locale";
          wordWrap = true;
        };
      };
    };
}
