{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  # lib.snowfall.fs.get-non-default-nix-files ./keymap/

  completion = import ./keymap/completion.nix { };
  help = import ./keymap/help.nix { };
  input = import ./keymap/input.nix { };
  manager = import ./keymap/manager.nix { };
  select = import ./keymap/select.nix { };
  tasks = import ./keymap/tasks.nix { };

  filetype = import ./theme/filetype.nix { };
  icons = import ./theme/icons.nix { };
  theme-manager = import ./theme/manager.nix { inherit config lib; };
  status = import ./theme/status.nix { };
  theme = import ./theme/theme.nix { };

  cfg = config.khanelinix.cli-apps.yazi;
in
{
  options.khanelinix.cli-apps.yazi = {
    enable = mkBoolOpt false "Whether or not to enable yazi.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      glow
      miller
      ouch
      ripgrep
      xdragon
      zoxide
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
      theme = lib.mkMerge [
        filetype
        icons
        theme-manager
        status
        theme
      ];
    };

    xdg.configFile = {
      "yazi" = {
        source = lib.cleanSourceWith { src = lib.cleanSource ./configs/.; };

        recursive = true;
      };
    };
  };
}
