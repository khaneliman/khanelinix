{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.hyprland;
in {
  options.khanelinix.desktop.hyprland = with types; {
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
      # start swayidle as part of hyprland, not sway
      khanelinix.suites.wlroots = enabled;

      systemd.user.services.swayidle.Install.WantedBy = lib.mkForce ["hyprland-session.target"];
      programs.waybar.systemd.target = "hyprland-session.target";

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;
        systemdIntegration = true;

        settings = {
          exec = [
            "notify-send --icon ~/.face -u normal \"Hello $(whoami)\""
          ];
        };

        extraConfig = ''
          source=~/.config/hypr/displays.conf
          source=~/.config/hypr/polish.conf

          env = XDG_DATA_DIRS,'${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}':$XDG_DATA_DIRS

          ${cfg.extraConfig}
        '';
      };
    };
}
