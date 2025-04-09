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

  completion = import ./keymap/completion.nix;
  help = import ./keymap/help.nix;
  input = import ./keymap/input.nix;
  manager = import ./keymap/manager.nix {
    inherit
      config
      lib
      namespace
      pkgs
      ;
  };
  select = import ./keymap/select.nix;
  tasks = import ./keymap/tasks.nix;

  cfg = config.${namespace}.programs.terminal.tools.yazi;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./configs/plugins;

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

      initLua = ./configs/init.lua;

      keymap = lib.mkMerge [
        completion
        help
        input
        manager
        select
        tasks
      ];

      flavors = {
        dark = "${yazi-flavors}/catppuccin-macchiato.yazi";
        light = "${yazi-flavors}/catppuccin-frappe.yazi";
      };

      plugins = {
        "arrow" = ./configs/plugins/arrow.yazi;
        "arrow-parent" = ./configs/plugins/arrow-parent.yazi;
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

      settings = import ./yazi.nix { inherit config lib pkgs; };
    };
  };
}
