{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  inputs,
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
  inherit (inputs) yazi-plugins;

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

    # Dumb workaround for no color with latest glow
    # https://github.com/Reledia/glow.yazi/issues/7
    home.sessionVariables = {
      "CLICOLOR_FORCE" = 1;
    };

    programs.yazi = {
      enable = true;
      package = pkgs.yazi;

      # NOTE: wrapper alias is yy
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;

      keymap = lib.mkMerge [
        completion
        help
        input
        manager
        select
        tasks
      ];
      settings = import ./yazi.nix { inherit config lib pkgs; };
    };

    xdg.configFile = {
      "yazi/init.lua".source = ./configs/init.lua;
      "yazi/plugins/chmod.yazi".source = "${yazi-plugins}/chmod.yazi";
      "yazi/plugins/diff.yazi".source = "${yazi-plugins}/diff.yazi";
      "yazi/plugins/full-border.yazi".source = "${yazi-plugins}/full-border.yazi";
      "yazi/plugins/glow.yazi".source = ./configs/plugins/glow.yazi;
      "yazi/plugins/jump-to-char.yazi".source = "${yazi-plugins}/jump-to-char.yazi";
      "yazi/plugins/max-preview.yazi".source = "${yazi-plugins}/max-preview.yazi";
      "yazi/plugins/miller.yazi".source = ./configs/plugins/miller.yazi;
      "yazi/plugins/ouch.yazi".source = ./configs/plugins/ouch.yazi;
      "yazi/plugins/smart-enter.yazi".source = "${yazi-plugins}/smart-enter.yazi";
      "yazi/plugins/smart-filter.yazi".source = "${yazi-plugins}/smart-filter.yazi";
      "yazi/plugins/sudo.yazi".source = ./configs/plugins/sudo.yazi;
    };
  };
}
