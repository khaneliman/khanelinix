{ config
, lib
, options
, pkgs
, inputs
, system
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.internal) enabled;
  inherit (inputs) hyprland;

  cfg = config.khanelinix.desktop.hyprland;
in
{
  options.khanelinix.desktop.hyprland = {
    enable = mkEnableOption "Hyprland.";
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to `~/.config/hypr/hyprland.conf`.
      '';
    };
  };

  imports = [
    ./apps.nix
    ./binds.nix
    ./variables.nix
    ./windowrules.nix
  ];

  config =
    mkIf cfg.enable
      {
        home.shellAliases = {
          hl = "cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -n 1)/hyprland.log";
          hl1 = "cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -n 2 | tail -n 1)/hyprland.log";
        };

        khanelinix = {
          desktop.addons = {
            rofi = enabled;
            hyprpaper = enabled;
          };

          suites = {
            wlroots = enabled;
          };
        };

        programs.waybar.systemd.target = "hyprland-session.target";

        systemd.user.services.swayidle.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];

        wayland.windowManager.hyprland = {
          enable = true;
          xwayland.enable = true;
          systemdIntegration = true;
          package = hyprland.packages.${system}.hyprland;

          settings = {
            exec = [
              "notify-send --icon ~/.face -u normal \"Hello $(whoami)\""
            ];
          };

          extraConfig = ''
            source=~/.config/hypr/displays.conf
            source=~/.config/hypr/polish.conf

            env = XDG_DATA_DIRS,'${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}':$XDG_DATA_DIRS
            env = HYPRLAND_TRACE,1

            ${cfg.extraConfig}
          '';
        };
      };
}
