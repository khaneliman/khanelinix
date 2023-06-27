{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.display-managers.gdm;
  gdmHome = config.users.users.gdm.home;
in {
  options.khanelinix.display-managers.gdm = with types; {
    enable = mkBoolOpt false "Whether or not to enable gdm.";
    wayland = mkBoolOpt true "Whether or not to use Wayland.";
    suspend =
      mkBoolOpt true "Whether or not to suspend the machine after inactivity.";
    monitors = mkOpt (nullOr path) null "The monitors.xml file to create.";
    defaultSession = mkOpt (nullOr types.str) null "The default session to use.";
  };

  config =
    mkIf cfg.enable
    {
      systemd.tmpfiles.rules =
        [
          "d ${gdmHome}/.config 0711 gdm gdm"
        ]
        ++ (
          # "./monitors.xml" comes from ~/.config/monitors.xml when GNOME
          # display information is updated.
          lib.optional (cfg.monitors != null) "L+ ${gdmHome}/.config/monitors.xml - - - - ${cfg.monitors}"
        );

      services.xserver = {
        enable = true;

        libinput.enable = true;
        displayManager = {
          defaultSession = lib.optional (cfg.defaultSession != null) cfg.defaultSession;

          gdm = {
            enable = true;
            inherit (cfg) wayland;
            autoSuspend = cfg.suspend;
          };
        };
        desktopManager.gnome.enable = true;
      };

      # @NOTE(jakehamilton): In order to set the cursor theme in GDM we have to specify it in the
      # dconf profile. However, the NixOS module doesn't provide an easy way to do this so the relevant
      # parts have been extracted from:
      # https://github.com/NixOS/nixpkgs/blob/96e18717904dfedcd884541e5a92bf9ff632cf39/nixos/modules/services/x11/display-managers/gdm.nix
      #
      # @NOTE(jakehamilton): The GTK and icon themes don't seem to affect recent GDM versions. I've
      # left them here as reference for the future.
      programs.dconf.profiles = {
        gdm = let
          customDconf = pkgs.writeTextFile {
            name = "gdm-dconf";
            destination = "/dconf/gdm-custom";
            text = ''
              ${optionalString (!gdmCfg.autoSuspend) ''
                [org/gnome/settings-daemon/plugins/power]
                sleep-inactive-ac-type='nothing'
                sleep-inactive-battery-type='nothing'
                sleep-inactive-ac-timeout=0
                sleep-inactive-battery-timeout=0
              ''}

              [org/gnome/desktop/interface]
              gtk-theme='${config.khanelinix.desktop.addons.gtk.theme.name}'
              cursor-theme='${config.khanelinix.desktop.addons.gtk.cursor.name}'
              icon-theme='${config.khanelinix.desktop.addons.gtk.icon.name}'
              font-theme='${config.khanelinix.system.fonts.default}'
              color-scheme='prefer-dark'
              enable-hot-corners=false
              enable-animations=true
            '';
          };

          customDconfDb = pkgs.stdenv.mkDerivation {
            name = "gdm-dconf-db";
            buildCommand = ''
              ${pkgs.dconf}/bin/dconf compile $out ${customDconf}/dconf
            '';
          };
        in
          mkForce (
            pkgs.stdenv.mkDerivation {
              name = "dconf-gdm-profile";
              buildCommand = ''
                # Check that the GDM profile starts with what we expect.
                if [ $(head -n 1 ${pkgs.gnome.gdm}/share/dconf/profile/gdm) != "user-db:user" ]; then
                  echo "GDM dconf profile changed, please update gtk/default.nix"
                  exit 1
                fi
                # Insert our custom DB behind it.
                sed '2ifile-db:${customDconfDb}' ${pkgs.gnome.gdm}/share/dconf/profile/gdm > $out
              '';
            }
          );
      };
    };
}
