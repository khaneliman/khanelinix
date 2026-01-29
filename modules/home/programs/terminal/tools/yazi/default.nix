{
  config,
  lib,
  pkgs,

  osConfig ? { },
  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (inputs) yazi-flavors;

  cfg = config.khanelinix.programs.terminal.tools.yazi;
  isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;

  mkYaziPlugin = pkgs.callPackage ./mkYaziPlugin.nix { };
in
{
  options.khanelinix.programs.terminal.tools.yazi = {
    enable = lib.mkEnableOption "yazi";
  };

  config = mkIf cfg.enable {

    programs.yazi = {
      enable = true;

      package =
        pkgs.yazi.override {
          _7zz = pkgs._7zz-rar; # Support for RAR extraction
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
            ++ optionalPluginPackage "piper" pkgs.eza
            ++ optionalPluginPackage "piper" pkgs.glow
            ++ optionalPluginPackage "piper" pkgs.xlsx2csv
            ++ lib.optionals (pkgs.stdenv.hostPlatform.isLinux && !isWSL) [
              pkgs.dragon-drop
            ];
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
        };

      # NOTE: wrapper alias is yy
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;

      inherit (import ./init.nix { inherit config lib; }) initLua;

      keymap = lib.mkMerge [
        (import ./keymap/completion.nix)
        (import ./keymap/help.nix)
        (import ./keymap/manager.nix {
          inherit
            config
            lib
            pkgs
            ;
        })
        (import ./keymap/select.nix)
        (import ./keymap/tasks.nix)
      ];

      flavors =
        if config.khanelinix.theme.nord.enable then
          {
            dark = "nord";
            light = "nord";
          }
        else if config.khanelinix.theme.catppuccin.enable then
          {
            dark = "${yazi-flavors}/catppuccin-macchiato.yazi";
            light = "${yazi-flavors}/catppuccin-frappe.yazi";
          }
        else
          { };

      plugins = {
        "arrow-parent" = ./plugins/arrow-parent.yazi;
        "smart-switch" = ./plugins/smart-switch.yazi;
        "smart-tab" = ./plugins/smart-tab.yazi;
        "folder-rules" = ./plugins/folder-rules.yazi;
        githead = mkYaziPlugin {
          pname = "githead.yazi";
          version = "26.1.22-unstable-2026-01-26";

          src = pkgs.fetchFromGitHub {
            owner = "llanosrocas";
            repo = "githead.yazi";
            rev = "317d09f728928943f0af72ff6ce31ea335351202";
            hash = "sha256-o2EnQYOxp5bWn0eLn0sCUXcbtu6tbO9pdUdoquFCTVw=";
          };
        };
        inherit (pkgs.yaziPlugins)
          chmod
          diff
          duckdb
          full-border
          git
          # glow
          jump-to-char
          # Faster, less accurate
          # mime-ext
          mount
          ouch
          piper
          restore
          smart-enter
          smart-filter
          sudo
          toggle-pane
          yatline
          ;
      }
      // lib.optionalAttrs config.khanelinix.theme.nord.enable {
        inherit (pkgs.yaziPlugins) nord;
      }
      // lib.optionalAttrs config.khanelinix.theme.catppuccin.enable {
        inherit (pkgs.yaziPlugins) yatline-catppuccin;
      };

      settings = lib.mkMerge [
        (import ./settings/input.nix)
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
          log = {
            enabled = false;
          };

          mgr = {
            ratio = [
              1
              3
              4
            ];
            linemode = "custom";
            show_hidden = true;
            show_symlink = true;
            sort_by = "alphabetical";
            sort_dir_first = true;
            sort_reverse = false;
            sort_sensitive = false;
          };

          pick = {
            open_title = "Open with:";
            open_origin = "hovered";
            open_offset = [
              0
              1
              50
              7
            ];
          };

          preview = {
            tab_size = 2;
            max_width = 600;
            max_height = 900;
            image_filter = "triangle";
            image_quality = 75;
            ueberzug_scale = 1;
            ueberzug_offset = [
              0
              0
              0
              0
            ];
            wrap = "yes";
          };

          tasks = {
            micro_workers = 10;
            macro_workers = 25;
            bizarre_retry = 5;
            image_alloc = 536870912; # 512MB
            image_bound = [
              0
              0
            ];
            suppress_preload = false;
          };

          which = {
            sort_by = "none";
            sort_sensitive = false;
            sort_reverse = false;
          };
        }
      ];
    };
  };
}
