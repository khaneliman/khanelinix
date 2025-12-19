{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.editors.vscode;
in
{
  options.khanelinix.programs.graphical.editors.vscode = {
    enable = mkEnableOption "Whether or not to enable vscode";
    declarativeConfig = mkBoolOpt true "Whether or not to enable vscode.";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".vscode/argv.json" = mkIf config.khanelinix.services.keyring.enable {
        text = builtins.toJSON {
          "enable-crash-reporter" = true;
          "crash-reporter-id" = "53a6c113-87c4-4f20-9451-dd67057ddb95";
          "password-store" = "gnome";
        };
      };
    };

    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      # TODO: add extensions not packaged with nixpkgs
      profiles =
        let
          commonExtensions =
            with pkgs.vscode-extensions;
            [
              adpyke.codesnap
              arrterian.nix-env-selector
              bbenoist.nix
              catppuccin.catppuccin-vsc
              catppuccin.catppuccin-vsc-icons
              christian-kohler.path-intellisense
              formulahendry.auto-close-tag
              formulahendry.auto-rename-tag
              github.vscode-github-actions
              github.vscode-pull-request-github
              gruntfuggly.todo-tree
              irongeek.vscode-env
              mkhl.direnv
              ms-vscode-remote.remote-ssh
              ms-vsliveshare.vsliveshare
              shardulm94.trailing-spaces
              usernamehw.errorlens
              wakatime.vscode-wakatime
              yzhang.markdown-all-in-one
            ]
            ++ lib.optionals config.khanelinix.suites.development.dockerEnable [
              ms-azuretools.vscode-docker
              ms-vscode-remote.remote-containers
            ]
            ++ lib.optionals config.khanelinix.suites.development.aiEnable [
              github.copilot
              github.copilot-chat
            ];
          commonSettings = {
            # Color theme
            "workbench.colorTheme" = lib.mkDefault "Catppuccin Macchiato";
            "catppuccin.accentColor" = lib.mkDefault "mauve";
            "workbench.iconTheme" = "vscode-icons";

            # TODO: Handle font config with stylix
            # Font family
            "editor.fontFamily" =
              lib.mkForce "MonaspaceArgon NF, Monaspace Argon NF, CascadiaCode,Consolas, monospace,Hack Nerd Font";
            "editor.codeLensFontFamily" =
              lib.mkForce "MonaspaceNeon NF, Monaspace Neon NF, Liga SFMono Nerd Font, CascadiaCode,Consolas, 'Courier New', monospace,Hack Nerd Font";
            "editor.inlayHints.fontFamily" = lib.mkForce "MonaspaceKrypton NF, Monaspace Krypton NF";
            "debug.console.fontFamily" = lib.mkForce "MonaspaceKrypton NF, Monaspace Krypton NF";
            "scm.inputFontFamily" = lib.mkForce "MonaspaceRadon NF, Monaspace Radon NF";
            "notebook.output.fontFamily" = lib.mkForce "MonaspaceRadon NF, Monapsace Radon";
            "chat.editor.fontFamily" = lib.mkForce "MonaspaceArgon NF, Monaspace Argon NF";
            "markdown.preview.fontFamily" =
              lib.mkForce "MonaspaceXenon NF, Monaspace Xenon NF; -apple-system, BlinkMacSystemFont, 'Segoe WPC', 'Segoe UI', system-ui, 'Ubuntu', 'Droid Sans', sans-serif";
            "terminal.integrated.fontFamily" =
              lib.mkForce "MonaspaceKrypton NF, Monaspace Krypton NF, JetBrainsMono Nerd Font Mono";

            # Git settings
            "git.allowForcePush" = true;
            "git.autofetch" = true;
            "git.blame.editorDecoration.enabled" = true;
            "git.confirmSync" = false;
            "git.enableSmartCommit" = true;
            "git.openRepositoryInParentFolders" = "always";
            "gitlens.gitCommands.skipConfirmations" = [
              "fetch:command"
              "stash-push:command"
              "switch:command"
              "branch-create:command"
            ];

            # Editor
            "editor.bracketPairColorization.enabled" = true;
            "editor.fontLigatures" =
              "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'ss09', 'ss10', 'dlig', 'liga'";
            "editor.fontSize" = lib.mkDefault 16;
            "editor.formatOnPaste" = true;
            "editor.formatOnSave" = true;
            "editor.formatOnType" = false;
            "editor.guides.bracketPairs" = true;
            "editor.guides.indentation" = true;
            "editor.inlineSuggest.enabled" = true;
            "editor.minimap.enabled" = false;
            "editor.minimap.renderCharacters" = false;
            "editor.overviewRulerBorder" = false;
            "editor.renderLineHighlight" = "all";
            "editor.smoothScrolling" = true;
            "editor.suggestSelection" = "first";

            # Terminal
            "terminal.integrated.automationShell.linux" = "nix-shell";
            "terminal.integrated.cursorBlinking" = true;
            "terminal.integrated.defaultProfile.linux" = "zsh";
            "terminal.integrated.enableBell" = false;
            "terminal.integrated.gpuAcceleration" = "on";

            # Workbench
            "workbench.editor.tabCloseButton" = "left";
            "workbench.fontAliasing" = "antialiased";
            "workbench.list.smoothScrolling" = true;
            "workbench.panel.defaultLocation" = "right";
            "workbench.startupEditor" = "none";

            # Miscellaneous
            "breadcrumbs.enabled" = true;
            "explorer.confirmDelete" = false;
            "files.trimTrailingWhitespace" = true;
            "javascript.updateImportsOnFileMove.enabled" = "always";
            "security.workspace.trust.enabled" = false;
            "todo-tree.filtering.includeHiddenFiles" = true;
            "typescript.updateImportsOnFileMove.enabled" = "always";
            "vsicons.dontShowNewVersionMessage" = true;
            "window.menuBarVisibility" = "toggle";
            "window.nativeTabs" = true;
            "window.restoreWindows" = "all";
            "window.titleBarStyle" = "custom";

            # LSP
            "C_Cpp.intelliSenseEngine" = "disabled";

            # Formatters
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "[cpp]" = {
              "editor.defaultFormatter" = "xaver.clang-format";
            };
            "[csharp]" = {
              "editor.defaultFormatter" = "ms-dotnettools.csharp";
            };
            "[dockerfile]" = {
              "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
            };
            "[gitconfig]" = {
              "editor.defaultFormatter" = "yy0931.gitconfig-lsp";
            };
            "[html]" = {
              "editor.defaultFormatter" = "vscode.html-language-features";
            };
            "[javascript]" = {
              "editor.defaultFormatter" = "vscode.typescript-language-features";
            };
            "[json]" = {
              "editor.defaultFormatter" = "vscode.json-language-features";
            };
            "[lua]" = {
              "editor.defaultFormatter" = "yinfei.luahelper";
            };
            "[shellscript]" = {
              "editor.defaultFormatter" = "foxundermoon.shell-format";
            };
            "[xml]" = {
              "editor.defaultFormatter" = "redhat.vscode-xml";
            };
          };
        in
        {
          default = {
            extensions = commonExtensions;
            enableUpdateCheck = lib.mkIf cfg.declarativeConfig false;
            enableExtensionUpdateCheck = lib.mkIf cfg.declarativeConfig false;
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
          };
          Angular = {
            extensions =
              with pkgs.vscode-extensions;
              commonExtensions
              ++ [
                angular.ng-template
              ];
          };
          C = {
            extensions =
              with pkgs.vscode-extensions;
              commonExtensions
              ++ [
                xaver.clang-format
                llvm-vs-code-extensions.vscode-clangd
              ];
          };
          DotNet = {
            extensions =
              with pkgs.vscode-extensions;
              commonExtensions
              ++ [
                ms-dotnettools.vscode-dotnet-runtime
                ms-dotnettools.csharp
                ms-dotnettools.csdevkit
              ];
            userSettings = lib.mkIf cfg.declarativeConfig (
              commonSettings
              // {
                "[csharp]" = {
                  "editor.defaultFormatter" = "ms-dotnettools.csharp";
                };
              }
            );
          };
          Java = {
            extensions =
              with pkgs.vscode-extensions;
              commonExtensions
              ++ [
                vscjava.vscode-java-pack
              ];
            userSettings = lib.mkIf cfg.declarativeConfig (
              commonSettings
              // {
                # LSP
                "java.jdt.ls.java.home" = "${pkgs.jdk17}/lib/openjdk";
                "java.configuration.runtimes" = [
                  "${pkgs.jdk8}/lib/openjdk"
                  "${pkgs.jdk17}/lib/openjdk"
                ];
                "redhat.telemetry.enabled" = false;

                # Formatters
                "[java]" = {
                  "editor.defaultFormatter" = "redhat.java";
                };

                # Custom file associations
                "files.associations" = {
                  "*.avsc" = "json";
                };
              }
            );
          };
          Nix = {
            extensions =
              with pkgs.vscode-extensions;
              commonExtensions
              ++ [
                arrterian.nix-env-selector
                bbenoist.nix
                mkhl.direnv
              ];
          };
          Python = {
            extensions =
              with pkgs.vscode-extensions;
              commonExtensions
              ++ [
                # FIXME: incorrect hash
                # error: hash mismatch in fixed-output derivation '/nix/store/fasa6wib6pa5vviq04a9v2vacap94jiv-ms-python-python.zip.drv':
                # ┃specified: sha256-8dc1uM/6iUNF+9y4yKH7w4/FsrzgVoOJlIFfQOvY8YM=
                # ┃got: sha256-uD6NWGD5GyYwd7SeoGsgYEH26NI+hDxCx3f2EhqoOXk=
                # ms-python.python
                ms-python.debugpy
                njpwerner.autodocstring
              ];
          };
          Rust = {
            extensions =
              with pkgs.vscode-extensions;
              commonExtensions
              ++ [
                rust-lang.rust-analyzer
              ];
          };
        };
    };

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      wakatime = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
