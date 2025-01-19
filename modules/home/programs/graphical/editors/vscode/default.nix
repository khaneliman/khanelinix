{
  config,
  khanelinix-lib,
  lib,
  osConfig,
  pkgs,
  root,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.editors.vscode;
in
{
  options.khanelinix.programs.graphical.editors.vscode = {
    enable = mkEnableOption "Whether or not to enable vscode.";
    declarativeConfig = mkBoolOpt false "Whether or not to enable vscode.";
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
      enableUpdateCheck = true;
      package = pkgs.vscode;

      # TODO: add extensions not packaged with nixpkgs
      extensions = with pkgs.vscode-extensions; [
        adpyke.codesnap
        arrterian.nix-env-selector
        bbenoist.nix
        catppuccin.catppuccin-vsc
        christian-kohler.path-intellisense
        dbaeumer.vscode-eslint
        eamodio.gitlens
        esbenp.prettier-vscode
        formulahendry.auto-close-tag
        formulahendry.auto-rename-tag
        github.vscode-github-actions
        github.vscode-pull-request-github
        gruntfuggly.todo-tree
        irongeek.vscode-env
        mkhl.direnv
        ms-azuretools.vscode-docker
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode-remote.remote-ssh
        ms-vscode.cpptools
        ms-vsliveshare.vsliveshare
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        shardulm94.trailing-spaces
        sumneko.lua
        timonwong.shellcheck
        usernamehw.errorlens
        vscode-icons-team.vscode-icons
        wakatime.vscode-wakatime
        xaver.clang-format
        yzhang.markdown-all-in-one
      ];

      userSettings = mkIf cfg.declarativeConfig {
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

        # LSP
        "C_Cpp.intelliSenseEngine" = "disabled";
        "java.jdt.ls.java.home" = "${pkgs.jdk17}/lib/openjdk";
        "java.configuration.runtimes" = [
          "${pkgs.jdk8}/lib/openjdk"
          "${pkgs.jdk17}/lib/openjdk"
          "${pkgs.jdk22}/lib/openjdk"
        ];
        "redhat.telemetry.enabled" = false;

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
        "[java]" = {
          "editor.defaultFormatter" = "redhat.java";
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

        # Custom file associations
        "files.associations" = {
          "*.avsc" = "json";
        };

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
      };
    };

    sops.secrets = lib.mkIf osConfig.khanelinix.security.sops.enable {
      wakatime = {
        sopsFile = root + "/secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
