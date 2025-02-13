{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  inputs,
  system,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  completion = import ./keymap/completion.nix { };
  help = import ./keymap/help.nix { };
  input = import ./keymap/input.nix { };
  manager = import ./keymap/manager.nix { inherit config; };
  select = import ./keymap/select.nix { };
  tasks = import ./keymap/tasks.nix { };
  inherit (inputs) yazi yazi-plugins;

  cfg = config.khanelinix.programs.terminal.tools.yazi;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./configs/plugins;

  options.khanelinix.programs.terminal.tools.yazi = {
    enable = mkBoolOpt false "Whether or not to enable yazi.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      miller
      ouch
      config.programs.ripgrep.package
      xdragon
      zoxide
      glow
    ];

    programs.yazi = {
      enable = true;
      package = yazi.packages.${system}.default;

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

      plugins = {
        "chmod" = "${yazi-plugins}/chmod.yazi";
        "diff" = "${yazi-plugins}/diff.yazi";
        "full-border" = "${yazi-plugins}/full-border.yazi";
        "glow" = ./configs/plugins/glow.yazi;
        "jump-to-char" = "${yazi-plugins}/jump-to-char.yazi";
        "max-preview" = "${yazi-plugins}/max-preview.yazi";
        "miller" = ./configs/plugins/miller.yazi;
        "ouch" = ./configs/plugins/ouch.yazi;
        "smart-enter" = "${yazi-plugins}/smart-enter.yazi";
        "smart-filter" = "${yazi-plugins}/smart-filter.yazi";
        "sudo" = ./configs/plugins/sudo.yazi;
      };

      settings = import ./yazi.nix { inherit config lib pkgs; };
    };
  };
}
