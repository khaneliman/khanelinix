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

      githubRoot = "${config.home.homeDirectory}/${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "Documents/"}github";

      t3codePackage =
        (pkgs.t3code.override {
          inherit (pkgs) gh;
          inherit (pkgs) git;

          enableClaude = false;
          enableCodex = false;
          enableGit = true;
          enableGitHub = true;
          enableJujutsu = false;
          enableOpencode = false;
        }).overrideAttrs
          (old: {
            src = inputs.t3code;
            version = inputs.t3code.shortRev or "dirty";
            pnpmDeps = pkgs.fetchPnpmDeps {
              inherit (old) pname;
              version = inputs.t3code.shortRev or "dirty";
              src = inputs.t3code;
              inherit (old) pnpmWorkspaces;
              pnpm = pkgs.pnpm_10;
              fetcherVersion = 4;
              hash = "sha256-+JqW/iI0wdRPxyL7y6ggD/+AvwwZXs9+fSUtG/SgW9s=";
            };
          });

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
            export PATH="/Applications/Tailscale.app/Contents/MacOS:/opt/homebrew/bin:/usr/local/bin:$PATH"

            if command -v tailscale >/dev/null 2>&1; then
              for _ in $(seq 1 30); do
                if tailscale status --json >/dev/null 2>&1; then
                  break
                fi
                sleep 2
              done
            fi

            exec ${lib.getExe' t3codePackage "t3code"} ${
              lib.escapeShellArgs [
                "serve"
                "--tailscale-serve"
                githubRoot
              ]
            }
          '';
        };
    in
    lib.mkIf cfg.enable {
      home.shellAliases.t3-remote = lib.mkIf tailscaleEnabled (lib.getExe remoteCommand);

      systemd.user.services.t3code-remote =
        lib.mkIf (tailscaleEnabled && pkgs.stdenv.hostPlatform.isLinux)
          {
            Unit = {
              Description = "T3 Code remote backend";
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

      launchd.agents.t3code-remote.config =
        lib.mkIf (tailscaleEnabled && pkgs.stdenv.hostPlatform.isDarwin)
          {
            ProgramArguments = [ (lib.getExe remoteCommand) ];
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/t3code-remote.out.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/t3code-remote.err.log";
            EnvironmentVariables = {
              PATH = "/Applications/Tailscale.app/Contents/MacOS:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
            };
          };

      programs.t3code = {
        enable = true;
        package = t3codePackage;

        userSettings = {
          addProjectBaseDirectory = githubRoot;
          textGenerationModelSelection = {
            instanceId = "codex";
            model = "gpt-5.4-mini";
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
            // lib.optionalAttrs (config.programs.claude-code.enable or false) {
              claudeAgent = {
                binaryPath = lib.getExe config.programs.claude-code.package;
              };
            }
            // lib.optionalAttrs (config.programs.opencode.enable or false) {
              opencode.binaryPath = lib.getExe config.programs.opencode.package;
            };
        };

        keybindings = [
          {
            key = "mod+j";
            command = "terminal.toggle";
          }
          {
            key = "mod+d";
            command = "terminal.split";
            when = "terminalFocus";
          }
          {
            key = "mod+n";
            command = "terminal.new";
            when = "terminalFocus";
          }
          {
            key = "mod+w";
            command = "terminal.close";
            when = "terminalFocus";
          }
          {
            key = "mod+d";
            command = "diff.toggle";
            when = "!terminalFocus";
          }
          {
            key = "mod+k";
            command = "commandPalette.toggle";
            when = "!terminalFocus";
          }
          {
            key = "mod+n";
            command = "chat.new";
            when = "!terminalFocus";
          }
          {
            key = "mod+shift+o";
            command = "chat.new";
            when = "!terminalFocus";
          }
          {
            key = "mod+shift+n";
            command = "chat.newLocal";
            when = "!terminalFocus";
          }
          {
            key = "mod+shift+m";
            command = "modelPicker.toggle";
            when = "!terminalFocus";
          }
          {
            key = "mod+o";
            command = "editor.openFavorite";
          }
          {
            key = "mod+shift+[";
            command = "thread.previous";
          }
          {
            key = "mod+shift+]";
            command = "thread.next";
          }
          {
            key = "mod+1";
            command = "thread.jump.1";
          }
          {
            key = "mod+2";
            command = "thread.jump.2";
          }
          {
            key = "mod+3";
            command = "thread.jump.3";
          }
          {
            key = "mod+4";
            command = "thread.jump.4";
          }
          {
            key = "mod+5";
            command = "thread.jump.5";
          }
          {
            key = "mod+6";
            command = "thread.jump.6";
          }
          {
            key = "mod+7";
            command = "thread.jump.7";
          }
          {
            key = "mod+8";
            command = "thread.jump.8";
          }
          {
            key = "mod+9";
            command = "thread.jump.9";
          }
          {
            key = "mod+1";
            command = "modelPicker.jump.1";
            when = "modelPickerOpen";
          }
          {
            key = "mod+2";
            command = "modelPicker.jump.2";
            when = "modelPickerOpen";
          }
          {
            key = "mod+3";
            command = "modelPicker.jump.3";
            when = "modelPickerOpen";
          }
          {
            key = "mod+4";
            command = "modelPicker.jump.4";
            when = "modelPickerOpen";
          }
          {
            key = "mod+5";
            command = "modelPicker.jump.5";
            when = "modelPickerOpen";
          }
          {
            key = "mod+6";
            command = "modelPicker.jump.6";
            when = "modelPickerOpen";
          }
          {
            key = "mod+7";
            command = "modelPicker.jump.7";
            when = "modelPickerOpen";
          }
          {
            key = "mod+8";
            command = "modelPicker.jump.8";
            when = "modelPickerOpen";
          }
          {
            key = "mod+9";
            command = "modelPicker.jump.9";
            when = "modelPickerOpen";
          }
        ];

        clientSettings = {
          settings = {
            autoOpenPlanSidebar = true;
            confirmThreadArchive = false;
            confirmThreadDelete = true;
            diffIgnoreWhitespace = true;
            diffWordWrap = false;
            favorites = [
              {
                provider = "claudeAgent";
                model = "claude-opus-4-8";
              }
              {
                provider = "claudeAgent";
                model = "claude-sonnet-5";
              }
              {
                provider = "codex";
                model = "gpt-5.5";
              }
              {
                provider = "codex";
                model = "gpt-5.4";
              }
              {
                provider = "codex";
                model = "gpt-5.4-mini";
              }
              {
                provider = "codex";
                model = "gpt-5.3-codex-spark";
              }
            ];
            sidebarProjectGroupingMode = "repository";
            sidebarProjectSortOrder = "updated_at";
            sidebarThreadSortOrder = "updated_at";
            timestampFormat = "locale";
          };
        };
      };
    };
}
