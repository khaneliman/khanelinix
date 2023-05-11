{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.hyprland;
  term = config.khanelinix.desktop.addons.term;
  hyprBasePath = inputs.dotfiles.outPath + "/dots/linux/hyprland/home/.config/hypr/";
  user = config.users.users.${config.khanelinix.user.name};
in
{
  options.khanelinix.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable Hyprland.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
    customConfigFiles = mkOpt attrs { } "Custom configuration files that can be used to override the default files.";
  };

  config = mkIf cfg.enable {
    khanelinix.apps = {
      partitionmanager = enabled;
    };

    # Desktop additions
    khanelinix.desktop.addons = {
      gtk = enabled;
      qt = enabled;
      kitty = enabled;
      rofi = enabled;
      swappy = enabled;
      kanshi = enabled;
      keyring = enabled;
      nautilus = enabled;
      electron-support = enabled;
      swaylock = enabled;
      swayidle = enabled;
      swaynotificationcenter = enabled;
      thunar = enabled;
      waybar = enabled;
      wlogout = enabled;
      wdisplays = enabled;
      xdg-portal = enabled;
    };

    khanelinix.home.configFile = with inputs;
      {
        "hypr/assets/square.png".source = hyprBasePath + "assets/square.png";
        "hypr/assets/diamond.png".source = hyprBasePath + "assets/diamond.png";
        "hypr/binds.conf".source = hyprBasePath + "binds.conf";
        "hypr/displays.conf".source = hyprBasePath + "displays.conf";
        "hypr/environment.conf".source = hyprBasePath + "environment.conf";
        "hypr/hyprland.conf".source = hyprBasePath + "hyprland.conf";
        "hypr/hyprpaper.conf".source = hyprBasePath + "hyprpaper.conf";
        "hypr/polish.conf".source = ./hypr/polish.conf;
        "hypr/variables.conf".source = hyprBasePath + "variables.conf";
        "hypr/windowrules.conf".source = hyprBasePath + "windowrules.conf";
        "mimeapps.list".source = dotfiles.outPath + "/dots/linux/hyprland/home/.config/mimeapps.list";
      }
      // cfg.customConfigFiles;

    khanelinix.home.file = with inputs; {
      ".local/bin/xdg-desktop-portal.sh".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/xdg-desktop-portal.sh";
      ".local/bin/hyprland_setup_dual_monitors.sh".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/hyprland_setup_dual_monitors.sh";
      ".local/bin/hyprland_cleanup_after_startup.sh".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/hyprland_cleanup_after_startup.sh";
      ".local/bin/hyprland_handle_monitor_connect.sh".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/hyprland_handle_monitor_connect.sh";
      ".local/bin/record_screen".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/record_screen";
    };

    programs.hyprland = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      # sddm
      khanelinix.catppuccin-sddm
      xwayland
      grim
      slurp
      swappy
      cliphist
      wl-clipboard
      wf-recorder
      libinput
      playerctl
      brightnessctl
      glib # for gsettings
      gtk3.out # for gtk-launch
      hyprpaper
      hyprpicker
      swayimg
      blueman
      networkmanagerapplet
      inputs.hyprland-contrib.packages.${pkgs.hostPlatform.system}.grimblast
    ];

    services.xserver = {
      enable = true;

      libinput.enable = true;
      displayManager = {
        # defaultSession = "hyprland";
        sddm = {
          enable = true;
          theme = "catppuccin";
        };
      };
    };

    system.activationScripts.postInstallHyprland = stringAfter [ "users" ] ''
      echo "Setting sddm permissions for user icon"
      ${pkgs.acl}/bin/setfacl -m u:sddm:x /home/${config.khanelinix.user.name}
      ${pkgs.acl}/bin/setfacl -m u:sddm:r /home/${config.khanelinix.user.name}/.face.icon
    '';
  };
}
