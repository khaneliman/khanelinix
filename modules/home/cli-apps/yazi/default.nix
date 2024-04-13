{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  completion = import ./keymap/completion.nix { };
  help = import ./keymap/help.nix { };
  input = import ./keymap/input.nix { };
  manager = import ./keymap/manager.nix { };
  select = import ./keymap/select.nix { };
  tasks = import ./keymap/tasks.nix { };

  cfg = config.khanelinix.cli-apps.yazi;
in
{
  options.khanelinix.cli-apps.yazi = {
    enable = mkBoolOpt false "Whether or not to enable yazi.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ripgrep
      zoxide
      xdragon
      glow
    ];

    programs.yazi = {
      enable = true;
      package = pkgs.yazi;

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
      settings = import ./yazi.nix { inherit lib pkgs; };
      theme = import ./theme.nix { inherit config lib; };
    };

    xdg.configFile = {
      "yazi" = {
        source = lib.cleanSourceWith { src = lib.cleanSource ./configs/.; };

        recursive = true;
      };
    };
  };
}
