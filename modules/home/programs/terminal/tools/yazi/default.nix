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
  manager = import ./keymap/manager.nix { inherit config; };
  select = import ./keymap/select.nix { };
  tasks = import ./keymap/tasks.nix { };

  filetype = import ./theme/filetype.nix { };
  icons = import ./theme/icons.nix { };
  theme-manager = import ./theme/manager.nix { inherit config lib; };
  status = import ./theme/status.nix { };
  theme = import ./theme/theme.nix { };

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
        source = lib.cleanSourceWith {
          filter =
            name: _type:
            let
              baseName = baseNameOf (toString name);
            in
            !lib.hasSuffix ".nix" baseName;
          src = lib.cleanSource ./configs/.;
        };

        recursive = true;
      };
    };
  };
}
