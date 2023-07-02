{
  pkgs,
  config,
  ...
}: {
  # Define an output to generate the final configuration file
  config = {
    khanelinix.home.configFile = {
      "hypr/polish.conf".source = pkgs.writeTextFile {
        name = "polish.conf";
        text = ''
          # ░█▀█░█▀█░█░░░▀█▀░█▀▀░█░█
          # ░█▀▀░█░█░█░░░░█░░▀▀█░█▀█
          # ░▀░░░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀

          # ░▀█▀░█░█░█▀▀░█▄█░█▀▀
          # ░░█░░█▀█░█▀▀░█░█░█▀▀
          # ░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀

          hyprctl setcursor ${config.khanelinix.desktop.addons.gtk.cursor.name} 32

          # gsettings
          exec-once = gsettings set org.gnome.desktop.interface gtk-theme '${config.khanelinix.desktop.addons.gtk.theme.name}'
          exec-once = gsettings set org.gnome.desktop.interface icon-theme '${config.khanelinix.desktop.addons.gtk.icon.name}'
          exec-once = gsettings set org.gnome.desktop.interface font-name '${config.khanelinix.system.fonts.default} 10'
          exec-once = gsettings set org.gnome.desktop.interface cursor-theme '${config.khanelinix.desktop.addons.gtk.cursor.name}'
          exec-once = gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
          exec-once = gsettings set org.gnome.desktop.interface enable-animations true

          # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀░░░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀
          # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀░░░█░░░█░█░█░█░█▀▀░░█░░█░█
          # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀
          # Move workspaces to correct monitor
          exec-once = hyprland_handle_monitor_connect.sh


          # ░█▀▀░█▀▄░█▀▀░█▀▀░▀█▀░█▀▀░█▀▄
          # ░█░█░█▀▄░█▀▀░█▀▀░░█░░█▀▀░█▀▄
          # ░▀▀▀░▀░▀░▀▀▀░▀▀▀░░▀░░▀▀▀░▀░▀

          # greeting
          exec = notify-send --icon ~/.face -u normal "Hello $(whoami)"
        '';
      };
    };
  };
}
