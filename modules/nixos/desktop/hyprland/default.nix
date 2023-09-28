{ config
, lib
, options
, pkgs
, inputs
, system
, ...
}:
let
  inherit (lib) types mkIf getExe';
  inherit (lib.internal) mkBoolOpt mkOpt enabled;
  inherit (inputs) hyprland-contrib hyprland;

  cfg = config.khanelinix.desktop.hyprland;
  programs = lib.makeBinPath [ config.programs.hyprland.package ];
in
{
  options.khanelinix.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable Hyprland.";
    customConfigFiles = mkOpt attrs { } "Custom configuration files that can be used to override the default files.";
    customFiles = mkOpt attrs { } "Custom files that can be used to override the default files.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
  };

  config =
    mkIf cfg.enable
      {
        environment.sessionVariables = {
          CLUTTER_BACKEND = "wayland";
          GDK_BACKEND = "wayland";
          HYPRLAND_LOG_WLR = "1";
          MOZ_ENABLE_WAYLAND = "1";
          MOZ_USE_XINPUT2 = "1";
          QT_QPA_PLATFORM = "wayland";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          SDL_VIDEODRIVER = "wayland";
          WLR_RENDERER = "vulkan";
          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_DESKTOP = "Hyprland";
          XDG_SESSION_TYPE = "wayland";
          _JAVA_AWT_WM_NONEREPARENTING = "1";
          __GL_GSYNC_ALLOWED = "0";
          __GL_VRR_ALLOWED = "0";
        };

        environment.systemPackages = with pkgs; [
          hyprpaper
          hyprpicker
          hyprland-contrib.packages.${hostPlatform.system}.grimblast
          khanelinix.record_screen
        ];

        khanelinix = {
          apps = {
            partitionmanager = enabled;
            gamemode = {
              startscript = ''
                ${getExe' pkgs.libnotify "notify-send"} 'GameMode started'
                export PATH=$PATH:${programs}
                export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /tmp/hypr | tail -1)
                hyprctl --batch 'keyword decoration:blur 0 ; keyword animations:enabled 0 ; keyword misc:no_vfr 1'
              '';

              endscript = ''
                ${getExe' pkgs.libnotify "notify-send"} 'GameMode stopped'
                export PATH=$PATH:${programs}
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
            kitty = enabled;
            nautilus = enabled;
            qt = enabled;
            thunar = enabled;
            xdg-portal = enabled;
          };

          display-managers.regreet = {
            enable = true;
          };

          home = {
            configFile =
              {
                "hypr/assets/square.png".source = ./hypr/assets/square.png;
                "hypr/assets/diamond.png".source = ./hypr/assets/diamond.png;
              }
              // cfg.customConfigFiles;

            file =
              { }
              // cfg.customFiles;
          };

          security = {
            keyring = enabled;
            polkit = enabled;
          };

          suites = {
            wlroots = enabled;
          };
        };

        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
          package = hyprland.packages.${system}.hyprland;
        };
      };
}
