{
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (inputs) yazi-flavors;

  cfg = config.${namespace}.programs.terminal.tools.yazi;
in
{
  options.${namespace}.programs.terminal.tools.yazi = {
    enable = lib.mkEnableOption "yazi";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        miller
        ouch
        config.programs.ripgrep.package
        zoxide
        glow
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        xdragon
      ];

    programs.yazi = {
      enable = true;

      # NOTE: wrapper alias is yy
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;

      inherit (import ./init.nix) initLua;

      keymap = lib.mkMerge [
        (import ./keymap/completion.nix)
        (import ./keymap/help.nix)
        (import ./keymap/input.nix)
        (import ./keymap/manager.nix {
          inherit
            config
            lib
            namespace
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
        "arrow" = ./plugins/arrow.yazi;
        "arrow-parent" = ./plugins/arrow-parent.yazi;
        inherit (pkgs.yaziPlugins)
          chmod
          diff
          full-border
          git
          glow
          jump-to-char
          miller
          mime-ext
          mount
          ouch
          restore
          smart-enter
          smart-filter
          sudo
          toggle-pane
          ;
      };

      settings = lib.mkMerge [
        (import ./settings/input.nix)
        (import ./settings/manager.nix)
        (import ./settings/open.nix)
        (import ./settings/opener.nix { inherit config lib pkgs; })
        (import ./settings/plugin.nix)
        (import ./settings/preview.nix)
        (import ./settings/tasks.nix)
        {
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

          which = {
            sort_by = "none";
            sort_sensitive = false;
            sort_reverse = false;
          };

          log = {
            enabled = false;
          };
        }
      ];
    };
  };
}
