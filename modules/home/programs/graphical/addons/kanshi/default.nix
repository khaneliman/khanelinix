{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.khanelinix.programs.graphical.addons.kanshi;
in
{
  options.khanelinix.programs.graphical.addons.kanshi = {
    enable = lib.mkEnableOption "Kanshi in the desktop environment";
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "Kanshi is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) {
      home.packages = with pkgs; [ kanshi ];

      # Kanshi configuration
      # See: https://git.sr.ht/~emersion/kanshi/tree/master/item/doc/kanshi.5.scd
      xdg.configFile."kanshi/config".source = ./config;

      systemd.user.services.kanshi = {
        Unit = {
          Description = "Kanshi output autoconfig";
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          Environment = [
            (lib.replaceStrings [ "%" ] [ "%%" ] (builtins.toJSON "XDG_CONFIG_HOME=${config.xdg.configHome}"))
          ];
          ExecCondition = /* bash */ ''
            ${getExe pkgs.bash} -c '[ -n "$WAYLAND_DISPLAY" ]'
          '';

          ExecStart = /* bash */ ''
            ${getExe pkgs.kanshi}
          '';

          RestartSec = 5;
          Restart = "always";
        };
      };
    })
  ];
}
