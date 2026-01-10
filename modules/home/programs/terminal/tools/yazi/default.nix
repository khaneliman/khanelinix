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
            optionalPluginPackage "ouch" pkgs.ouch
            ++ optionalPluginPackage "duckdb" pkgs.duckdb
            ++ optionalPluginPackage "piper" pkgs.bat
            ++ optionalPluginPackage "piper" pkgs.eza
            ++ optionalPluginPackage "piper" pkgs.glow
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

      flavors = {
        dark = "${yazi-flavors}/catppuccin-macchiato.yazi";
        light = "${yazi-flavors}/catppuccin-frappe.yazi";
      };

      plugins = {
        "arrow-parent" = ./plugins/arrow-parent.yazi;
        "smart-tab" = ./plugins/smart-tab.yazi;
        # TODO: remove once merged
        yatline = pkgs.yaziPlugins.yatline.overrideAttrs {
          patches = [
            (pkgs.fetchpatch {
              url = "https://github.com/imsi32/yatline.yazi/pull/71.patch";
              hash = "sha256-YUFlDzSx8X4XIeYVOX+PRVZxND7588nl0vr3V+h6hus=";
            })
          ];
        };
        # TODO: remove once merged
        yatline-githead = pkgs.yaziPlugins.yatline-githead.overrideAttrs {
          patches = [
            (pkgs.fetchpatch {
              url = "https://github.com/imsi32/yatline-githead.yazi/pull/7.patch";
              hash = "sha256-0W2gE3QlSWTYsWhow09zWxNkZlNDd+mZP9FMFP0P5pc=";
            })
          ];
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
          # FIXME: broken
          # yatline
          # FIXME: deprecations
          # yatline-githead
          yatline-catppuccin
          ;
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
            sixel_fraction = 15;
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
