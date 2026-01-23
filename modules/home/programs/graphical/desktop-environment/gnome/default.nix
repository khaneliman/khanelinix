{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) default-attrs mkBoolOpt mkOpt;

  cfg = config.khanelinix.programs.graphical.desktop-environment.gnome;

  get-wallpaper = wallpaper: if lib.isDerivation wallpaper then toString wallpaper else wallpaper;
  wallpaperPath = name: lib.khanelinix.theme.wallpaperPath { inherit config pkgs name; };
in
{
  options.khanelinix.programs.graphical.desktop-environment.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment customization";

    shell = mkOpt (types.submodule {
      freeformType = types.attrsOf types.anything;
      options = {
        favorite-apps = mkOpt (types.listOf types.str) [
          "org.gnome.Nautilus.desktop"
          "org.gnome.Console.desktop"
        ] "List of favorite applications";
        disable-user-extensions = mkBoolOpt false "Whether to disable user extensions";
        enabled-extensions = mkOpt (types.listOf types.str) [
          "native-window-placement@gnome-shell-extensions.gcampax.github.com"
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
        ] "List of enabled extensions";
      };
    }) { } "GNOME Shell configuration";

    desktop = mkOpt (types.submodule {
      freeformType = types.attrsOf types.anything;
      options = {
        interface =
          mkOpt
            (types.submodule {
              freeformType = types.attrsOf types.anything;
              options = {
                color-scheme = mkOpt (types.enum [
                  "default"
                  "prefer-dark"
                ]) "prefer-dark" "Interface color scheme";
                enable-hot-corners = mkBoolOpt false "Enable hot corners";
              };
            })
            {
              color-scheme = "prefer-dark";
              enable-hot-corners = false;
            }
            "Desktop interface settings";

        background =
          mkOpt
            (types.submodule {
              freeformType = types.attrsOf types.anything;
              options = {
                picture-uri = mkOpt types.str "" "Light wallpaper URI";
                picture-uri-dark = mkOpt types.str "" "Dark wallpaper URI";
              };
            })
            {
              picture-uri = get-wallpaper (wallpaperPath config.khanelinix.theme.wallpaper.primary);
              picture-uri-dark = get-wallpaper (wallpaperPath config.khanelinix.theme.wallpaper.secondary);
            }
            "Desktop background settings";

        screensaver =
          mkOpt
            (types.submodule {
              freeformType = types.attrsOf types.anything;
              options = {
                picture-uri = mkOpt types.str "" "Light screensaver URI";
                picture-uri-dark = mkOpt types.str "" "Dark screensaver URI";
              };
            })
            {
              picture-uri = get-wallpaper (wallpaperPath config.khanelinix.theme.wallpaper.primary);
              picture-uri-dark = get-wallpaper (wallpaperPath config.khanelinix.theme.wallpaper.secondary);
            }
            "Screensaver settings";

        peripherals = mkOpt (types.submodule {
          freeformType = types.attrsOf types.anything;
          options = {
            touchpad =
              mkOpt
                (types.submodule {
                  freeformType = types.attrsOf types.anything;
                  options = {
                    disable-while-typing = mkBoolOpt false "Disable touchpad while typing";
                  };
                })
                {
                  disable-while-typing = false;
                }
                "Touchpad settings";
          };
        }) { } "Peripheral device settings";

        wm = mkOpt (types.submodule {
          freeformType = types.attrsOf types.anything;
          options = {
            preferences =
              mkOpt
                (types.submodule {
                  freeformType = types.attrsOf types.anything;
                  options = {
                    num-workspaces = mkOpt types.int 10 "Number of workspaces";
                  };
                })
                {
                  num-workspaces = 10;
                }
                "Window manager preferences";

            keybindings =
              mkOpt
                (types.submodule {
                  freeformType = types.attrsOf types.anything;
                  options = {
                    enable-workspace-shortcuts = mkBoolOpt true "Enable workspace switching shortcuts";
                    enable-move-to-workspace-shortcuts = mkBoolOpt true "Enable move to workspace shortcuts";
                  };
                })
                (
                  let
                    workspaceCount = cfg.desktop.wm.preferences.num-workspaces or 10;
                  in
                  lib.foldl'
                    (
                      acc: i:
                      let
                        num = if i == 10 then "0" else toString i;
                      in
                      acc
                      // {
                        "move-to-workspace-${toString i}" = [ "<Shift><Super>${num}" ];
                        "switch-to-application-${toString i}" = [ "<Super>${num}" ];
                        "switch-to-workspace-${toString i}" = [ "<Control><Alt>${num}" ];
                      }
                    )
                    {
                      "move-to-workspace-right" = [
                        "<Shift><Super>Right"
                        "<Shift><Super>l"
                      ];
                      "move-to-workspace-left" = [
                        "<Shift><Super>Left"
                        "<Shift><Super>h"
                      ];
                      "switch-to-workspace-right" = [
                        "<Control><Alt>Right"
                        "<Control><Alt>l"
                      ];
                      "switch-to-workspace-left" = [
                        "<Control><Alt>Left"
                        "<Control><Alt>h"
                      ];
                      "switch-applications" = [
                        "<Super><Tab>"
                      ];
                      "switch-applications-backward" = [
                        "<Shift><Super><Tab>"
                      ];
                    }
                    (lib.range 1 workspaceCount)
                )

                "Window manager keybindings";
          };
        }) { } "Window manager settings";
      };
    }) { } "Desktop settings";

    mutter =
      mkOpt
        (types.submodule {
          freeformType = types.attrsOf types.anything;
          options = {
            edge-tiling = mkBoolOpt false "Enable edge tiling";
            dynamic-workspaces = mkBoolOpt false "Enable dynamic workspaces";
          };
        })
        {
          edge-tiling = false;
          dynamic-workspaces = false;
        }
        "Mutter settings";

    extensions = mkOpt (types.attrsOf types.anything) {
      "dash-to-dock" = {
        autohide = true;
        dock-fixed = false;
        dock-position = "BOTTOM";
        pressure-threshold = 200.0;
        require-pressure-to-show = true;
        show-favorites = true;
        hot-keys = false;
      };

      "just-perfection" = {
        panel-size = 48;
        activities-button = false;
      };

      "Logo-menu" = {
        hide-softwarecentre = true;
        menu-button-icon-click-type = 3;
        menu-button-icon-image = 23;
        menu-button-terminal = "gnome-terminal";
      };

      "aylurs-widgets" = {
        background-clock = false;
        battery-bar = false;
        dash-board = false;
        date-menu-date-format = "%H:%M  %B %m";
        date-menu-hide-clocks = true;
        date-menu-hide-system-levels = true;
        date-menu-hide-user = true;
        date-menu-indicator-position = 2;
        media-player = false;
        media-player-prefer = "firefox";
        notification-indicator = false;
        power-menu = false;
        quick-toggles = false;
        workspace-indicator = false;
      };

      "top-bar-organizer" = {
        left-box-order = [
          "menuButton"
          "activities"
          "dateMenu"
          "appMenu"
        ];
        center-box-order = [ "Space Bar" ];
        right-box-order = [
          "keyboard"
          "EmojisMenu"
          "wireless-hid"
          "drive-menu"
          "vitalsMenu"
          "screenRecording"
          "screenSharing"
          "dwellClick"
          "a11y"
          "quickSettings"
        ];
      };

      "space-bar/shortcuts" = {
        enable-activate-workspace-shortcuts = false;
      };

      "space-bar/behavior" = {
        show-empty-workspaces = false;
      };

      "gtile" = {
        show-icon = false;
      };
    } "GNOME extension settings as attribute set where keys are extension names";

    settings = mkOpt (types.attrsOf types.anything) { } "Additional dconf settings";
  };

  config = mkIf cfg.enable {
    dconf.settings = lib.recursiveUpdate (
      lib.optionalAttrs (cfg.shell != { }) {
        "org/gnome/shell" = default-attrs cfg.shell;
      }
      // lib.optionalAttrs (cfg.desktop.interface != { }) {
        "org/gnome/desktop/interface" = default-attrs cfg.desktop.interface;
      }
      // lib.optionalAttrs (cfg.desktop.peripherals.touchpad != { }) {
        "org/gnome/desktop/peripherals/touchpad" = default-attrs cfg.desktop.peripherals.touchpad;
      }
      // lib.optionalAttrs (cfg.desktop.wm.preferences != { }) {
        "org/gnome/desktop/wm/preferences" = default-attrs cfg.desktop.wm.preferences;
      }
      // lib.optionalAttrs (cfg.desktop.wm.keybindings != { }) {
        "org/gnome/desktop/wm/keybindings" = default-attrs cfg.desktop.wm.keybindings;
      }
      // lib.optionalAttrs (cfg.mutter != { }) {
        "org/gnome/mutter" = default-attrs cfg.mutter;
      }
      // lib.optionalAttrs (cfg.desktop.background != { }) {
        "org/gnome/desktop/background" = default-attrs cfg.desktop.background;
      }
      // lib.optionalAttrs (cfg.desktop.screensaver != { }) {
        "org/gnome/desktop/screensaver" = default-attrs cfg.desktop.screensaver;
      }
      // lib.mapAttrs' (
        name: settings: lib.nameValuePair "org/gnome/shell/extensions/${name}" settings
      ) cfg.extensions
    ) cfg.settings;
  };
}
