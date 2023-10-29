{ config
, lib
, options
, pkgs
, inputs
, system
, ...
}:
let
  inherit (lib) mkIf mkEnableOption getExe;
  inherit (lib.internal) enabled;
  inherit (inputs) hyprland;

  cfg = config.khanelinix.desktop.hyprland;
in
{
  options.khanelinix.desktop.hyprland = {
    enable = mkEnableOption "Hyprland.";
    appendConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to bottom of `~/.config/hypr/hyprland.conf`.
      '';
    };
    prependConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to top of `~/.config/hypr/hyprland.conf`.
      '';
    };
  };

  imports = [
    ./apps.nix
    ./binds.nix
    ./variables.nix
    ./windowrules.nix
    ./workspacerules.nix
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

          extraConfig = ''
            ${cfg.prependConfig}

            source=~/.config/hypr/displays.conf
            source=~/.config/hypr/polish.conf

            env = XDG_DATA_DIRS,'${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}':$XDG_DATA_DIRS
            env = HYPRLAND_TRACE,1

            ${cfg.appendConfig}
          '';

          package = hyprland.packages.${system}.hyprland;

          settings = {
            exec = [
              "${getExe pkgs.libnotify} --icon ~/.face -u normal \"Hello $(whoami)\""
            ];
          };

          systemd = {
            enable = true;
          };

          xwayland.enable = true;
        };
      };
}
