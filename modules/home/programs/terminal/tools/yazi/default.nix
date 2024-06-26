{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  completion = import ./keymap/completion.nix { };
  help = import ./keymap/help.nix { };
  input = import ./keymap/input.nix { };
  manager = import ./keymap/manager.nix { inherit config namespace; };
  select = import ./keymap/select.nix { };
  tasks = import ./keymap/tasks.nix { };

  cfg = config.${namespace}.programs.terminal.tools.yazi;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./configs/plugins;

  options.${namespace}.programs.terminal.tools.yazi = {
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
      settings = import ./yazi.nix { inherit lib pkgs; };
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
