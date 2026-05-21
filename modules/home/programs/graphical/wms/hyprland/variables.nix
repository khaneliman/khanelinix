{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
        curve = [
          {
            _args = [
              "easein"
              {
                type = "bezier";
                points = [
                  [
                    0.47
                    0
                  ]
                  [
                    0.745
                    0.715
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "myBezier"
              {
                type = "bezier";
                points = [
                  [
                    0.05
                    0.9
                  ]
                  [
                    0.1
                    1.05
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "overshot"
              {
                type = "bezier";
                points = [
                  [
                    0.13
                    0.99
                  ]
                  [
                    0.29
                    1.1
                  ]
                ];
              }
            ];
          }
          {
            _args = [
              "scurve"
              {
                type = "bezier";
                points = [
                  [
                    0.98
                    0.01
                  ]
                  [
                    0.02
                    0.98
                  ]
                ];
              }
            ];
          }
        ];

        animation = [
          {
            leaf = "border";
            enabled = true;
            speed = 10;
            bezier = "default";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 10;
            bezier = "default";
          }
          {
            leaf = "windows";
            enabled = true;
            speed = 5;
            bezier = "overshot";
            style = "popin 10%";
          }
          {
            leaf = "windowsOut";
            enabled = true;
            speed = 7;
            bezier = "default";
            style = "popin 10%";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 6;
            bezier = "overshot";
            style = "slide";
          }
        ];

        config = {
          animations.enabled = true;

          cursor = {
            enable_hyprcursor = true;
            sync_gsettings_theme = true;
            hide_on_key_press = true;
          };

          debug = mkIf cfg.enableDebug {
            colored_stdout_logs = true;
            disable_logs = false;
            enable_stdout_logs = true;
            error_position = -1;
          };

          decoration = {
            active_opacity = 0.95;
            fullscreen_opacity = 1.0;
            inactive_opacity = 0.9;
            rounding = 10;

            blur = {
              enabled = true;
              passes = 4;
              size = 5;
              xray = true;
            };

            shadow = {
              enabled = true;
              range = 20;
              render_power = 3;
              color = lib.mkDefault "0x55161925";
              color_inactive = lib.mkDefault "0x22161925";
            };
          };

          dwindle = {
            preserve_split = true;
            special_scale_factor = 0.9;
          };

          ecosystem = {
            no_donation_nag = true;
            no_update_news = true;
          };

          general = {
            border_size = 2;
            "col.active_border" = lib.mkDefault "rgba(7793D1FF)";
            "col.inactive_border" = lib.mkDefault "rgb(5e6798)";
            gaps_in = 5;
            gaps_out = 20;
            layout = "dwindle";
          };

          group = {
            insert_after_current = true;
            focus_removed_window = true;
            "col.border_active" = lib.mkDefault "rgba(88888888)";
            "col.border_inactive" = lib.mkDefault "rgba(00000088)";

            groupbar = {
              gradients = false;
              font_size = 14;
              render_titles = false;
              scrolling = true;
            };
          };

          input = {
            follow_mouse = 1;
            kb_layout = "us";
            numlock_by_default = true;

            touchpad = {
              disable_while_typing = true;
              natural_scroll = false;
              tap_to_click = true;
            };

            sensitivity = 0;
            force_no_accel = true;
            scroll_factor = 1.0;
            emulate_discrete_scroll = 1;
          };

          master.new_status = "master";

          misc = {
            allow_session_lock_restore = true;
            disable_hyprland_logo = true;
            enable_swallow = true;
            focus_on_activate = false;
            font_family = lib.mkDefault "MonaspaceNeon NF";
            key_press_enables_dpms = true;
            middle_click_paste = false;
            mouse_move_enables_dpms = true;
            swallow_regex = ".*(foot|thunar|nemo|wezterm).*";
            vrr = 0;
          };

          render = {
            new_render_scheduling = true;
            direct_scanout = 2;
          };

          xwayland.force_zero_scaling = false;
        };
      };
    };
  };
}
