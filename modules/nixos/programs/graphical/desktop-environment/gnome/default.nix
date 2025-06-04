{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    ;
  inherit (lib.${namespace})
    enabled
    mkBoolOpt
    mkOpt
    ;

  cfg = config.${namespace}.programs.graphical.desktop-environment.gnome;
  gdmHome = config.users.users.gdm.home;
in
{
  options.${namespace}.programs.graphical.desktop-environment.gnome = with types; {
    enable = lib.mkEnableOption "using Gnome as the desktop environment";
    color-scheme = mkOpt (enum [
      "light"
      "dark"
    ]) "dark" "The color scheme to use.";
    extensions = mkOpt (listOf package) [
      # appindicator
      # aylurs-widgets
      # dash-to-dock
      # emoji-selector
      # gsconnect
      # gtile
      # just-perfection
      # logo-menu
      # no-overview
      # remove-app-menu
      # space-bar
      # top-bar-organizer
      # wireless-hid
    ] "Extra Gnome extensions to install.";
    monitors = mkOpt (nullOr path) null "The monitors.xml file to create.";
    suspend = mkBoolOpt true "Whether or not to suspend the machine after inactivity.";
    wayland = mkBoolOpt true "Whether or not to use Wayland.";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages =
        with pkgs;
        [
          gnome-tweaks
          nautilus-python
          wl-clipboard
        ]
        ++ cfg.extensions;

      gnome.excludePackages = with pkgs; [
        epiphany
        geary
        gnome-font-viewer
        gnome-maps
        gnome-system-monitor
        gnome-tour
      ];
    };

    khanelinix = {
      # TODO: gnome equivalent on home-manager
      # desktop.addons = {
      # electron-support = enabled;
      # kitty = enabled;
      # };

      display-managers.gdm = {
        inherit (cfg) enable wayland;
        autoSuspend = cfg.suspend;
      };

      system.xkb.enable = true;

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };

    # Open firewall for samba connections to work.
    networking.firewall.extraCommands = "iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns";

    programs.kdeconnect = {
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };

    # Required for app indicators
    services = {
      udev.packages = with pkgs; [ gnome-settings-daemon ];
      desktopManager.gnome.enable = true;
    };

    systemd = {
      tmpfiles.rules =
        [ "d ${gdmHome}/.config 0711 gdm gdm" ]
        ++ (
          # "./monitors.xml" comes from ~/.config/monitors.xml when GNOME
          # display information is updated.
          lib.optional (cfg.monitors != null) "L+ ${gdmHome}/.config/monitors.xml - - - - ${cfg.monitors}"
        );
    };
  };
}
