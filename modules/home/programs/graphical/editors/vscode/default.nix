{
  config,
  lib,
  pkgs,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.editors.vscode;
in
{
  options.${namespace}.programs.graphical.editors.vscode = {
    enable = mkEnableOption "Whether or not to enable vscode.";
    declarativeConfig = mkBoolOpt true "Whether or not to enable vscode.";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".vscode/argv.json" = mkIf config.${namespace}.services.keyring.enable {
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
              eamodio.gitlens
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
            ];
          commonSettings = {
            # Color theme
            "workbench.colorTheme" = "Catppuccin Macchiato";
            "catppuccin.accentColor" = "mauve";
            "workbench.iconTheme" = "vscode-icons";

            # Font family
            "editor.fontFamily" =
              "MonaspiceAr Nerd Font, CaskaydiaCove Nerd Font,Consolas, monospace,Hack Nerd Font";
            "editor.codeLensFontFamily" =
              "MonaspiceNe Nerd Font, Liga SFMono Nerd Font, CaskaydiaCove Nerd Font,Consolas, 'Courier New', monospace,Hack Nerd Font";
            "editor.inlayHints.fontFamily" = "MonaspiceKr Nerd Font";
            "debug.console.fontFamily" = "Monaspace Krypton";
            "scm.inputFontFamily" = "Monaspace Radon";
            "notebook.output.fontFamily" = "Monapsace Radon";
            "chat.editor.fontFamily" = "Monaspace Argon";
            "markdown.preview.fontFamily" =
              "Monaspace Xenon; -apple-system, BlinkMacSystemFont, 'Segoe WPC', 'Segoe UI', system-ui, 'Ubuntu', 'Droid Sans', sans-serif";
            "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font Mono";

            # Git settings
            "git.allowForcePush" = true;
            "git.autofetch" = true;
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
            "editor.fontLigatures" = true;
            "editor.fontSize" = 16;
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
                ms-python.python
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

    sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
      wakatime = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
