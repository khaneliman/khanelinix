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
  cfg = config.khanelinix.desktop.hyprland;
  hyprBasePath = inputs.dotfiles.outPath + "/dots/linux/hyprland/home/.config/hypr/";
in {
  options.khanelinix.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable Hyprland.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
    customConfigFiles = mkOpt attrs {} "Custom configuration files that can be used to override the default files.";
    customFiles = mkOpt attrs {} "Custom files that can be used to override the default files.";
  };

  config =
    mkIf cfg.enable
    {
      khanelinix = {
        apps = {
          partitionmanager = enabled;
          gamemode = {
            startscript = ''
              export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /tmp/hypr | tail -1)
              hyprctl --batch 'keyword decoration:blur 0 ; keyword animations:enabled 0 ; keyword misc:no_vfr 1'
            '';

            endscript = ''
              export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /tmp/hypr | tail -1)
              hyprctl --batch 'keyword decoration:blur 1 ; keyword animations:enabled 1 ; keyword misc:no_vfr 0'
            '';
          };
        };

        # Desktop additions
        desktop.addons = {
          # eww = enabled;
          gtk = enabled;
          kanshi = enabled;
          keyring = enabled;
          kitty = enabled;
          nautilus = enabled;
          qt = enabled;
          rofi = enabled;
          thunar = enabled;
          xdg-portal = enabled;
        };

        display-managers = {
          greetd = enabled;
        };

        home = {
          configFile = with inputs;
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

          file = with inputs;
            {
              ".local/bin/xdg-desktop-portal.sh".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/xdg-desktop-portal.sh";
              ".local/bin/hyprland_setup_dual_monitors.sh".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/hyprland_setup_dual_monitors.sh";
              ".local/bin/hyprland_cleanup_after_startup.sh".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/hyprland_cleanup_after_startup.sh";
              ".local/bin/hyprland_handle_monitor_connect.sh".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/hyprland_handle_monitor_connect.sh";
              ".local/bin/record_screen".source = dotfiles.outPath + "/dots/linux/hyprland/home/.local/bin/record_screen";
            }
            // cfg.customFiles;
        };

        suites = {
          wlroots = enabled;
        };
      };

      programs.hyprland = {
        enable = true;
      };

      environment.systemPackages = with pkgs; [
        hyprpaper
        hyprpicker
        inputs.hyprland-contrib.packages.${pkgs.hostPlatform.system}.grimblast
      ];
    };
}
