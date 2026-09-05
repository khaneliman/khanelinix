{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.yazi;
  isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;

in
{
  options.khanelinix.programs.terminal.tools.yazi = {
    enable = lib.mkEnableOption "yazi";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;

      package = pkgs.yazi.override (
        {
          _7zz = pkgs._7zz-rar; # Support for RAR extraction
        }
        // lib.optionalAttrs isWSL {
          optionalDeps = with pkgs; [
            # Keep essential tools, exclude heavy media dependencies
            jq
            _7zz-rar
            fd
            ripgrep
            fzf
            zoxide
            # Remove: ffmpeg, poppler-utils, imagemagick, chafa, resvg
          ];
        }
      );

      extraPackages =
        let
          optionalPluginPackage =
            plugin: package: lib.optional (builtins.hasAttr plugin config.programs.yazi.plugins) package;
        in
        (with pkgs; [
          atool
          exiftool
          mediainfo
          unar
          undmg
        ])
        ++ optionalPluginPackage "ouch" pkgs.ouch
        ++ optionalPluginPackage "duckdb" pkgs.duckdb
        ++ optionalPluginPackage "piper" pkgs.bat
        ++ optionalPluginPackage "piper" pkgs.glow
        ++ optionalPluginPackage "piper" pkgs.xlsx2csv
        ++ optionalPluginPackage "piper" pkgs.sqlite
        ++ optionalPluginPackage "restore" pkgs.trash-cli
        ++ lib.optionals (pkgs.stdenv.hostPlatform.isLinux && !isWSL) [
          pkgs.dragon-drop
        ];

      enableBashIntegration = config.programs.bash.enable && config.home.shell.enableBashIntegration;
      enableFishIntegration = config.programs.fish.enable && config.home.shell.enableFishIntegration;
      enableNushellIntegration =
        config.programs.nushell.enable && config.home.shell.enableNushellIntegration;
      enableZshIntegration = config.programs.zsh.enable && config.home.shell.enableZshIntegration;
      shellWrapperName = "y";

      inherit (import ./init.nix { inherit config lib; }) initLua;

      vfs = import ./vfs.nix { inherit config lib; };

      keymap = lib.mkMerge [
        (import ./keymap/completion.nix)
        (import ./keymap/help.nix)
        (import ./keymap/manager.nix {
          inherit
            config
            isWSL
            lib
            pkgs
            ;
        })
        (import ./keymap/pick.nix)
        (import ./keymap/tasks.nix)
      ];

      plugins = {
        duckdb = {
          package = pkgs.yaziPlugins.duckdb;
          setup = true;
          settings = {
            mode = "standard";
            cache_size = 500;
          };
        };
        full-border = {
          package = pkgs.yaziPlugins.full-border;
          setup = true;
        };
        git = {
          package = pkgs.yaziPlugins.git;
          setup = true;
        };
        "arrow-parent" = ./plugins/arrow-parent.yazi;
        "smart-switch" = ./plugins/smart-switch.yazi;
        "smart-tab" = ./plugins/smart-tab.yazi;
        inherit (pkgs.yaziPlugins)
          chmod
          diff
          githead
          # glow
          jump-to-char
          # Faster, less accurate
          # mime-ext
          mount
          ouch
          piper
          smart-enter
          smart-filter
          sudo
          toggle-pane
          yatline
          ;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        inherit (pkgs.yaziPlugins) restore;
      }
      // lib.optionalAttrs config.khanelinix.theme.nord.enable {
        inherit (pkgs.yaziPlugins) nord;
      }
      // lib.optionalAttrs config.khanelinix.theme.catppuccin.enable {
        inherit (pkgs.yaziPlugins) yatline-catppuccin;
      };

      # Yazi configuration
      # See: https://yazi-rs.github.io/docs/configuration/overview/
      settings = lib.mkMerge [
        (import ./settings/image-annotation.nix {
          inherit
            config
            isWSL
            lib
            pkgs
            ;
        })
        (import ./settings/open.nix)
        (import ./settings/opener.nix {
          inherit
            config
            lib
            osConfig
            pkgs
            ;
        })
        (import ./settings/plugin.nix { inherit config lib; })
        {
          mgr = {
            ratio = [
              1
              3
              4
            ];
            linemode = "custom";
            show_hidden = true;
            sort_fallback = "natural";
          };

          preview.wrap = "yes";
        }
      ];
    };
  };
}
