{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.launchers.walker;
in
{
  options.khanelinix.programs.graphical.launchers.walker = {
    enable = lib.mkEnableOption "walker in the desktop environment";
  };

  config = mkIf cfg.enable {
    services.walker = {
      enable = true;
      systemd.enable = true;

      settings = {
        theme = "khanelinix";
        close_when_open = true;
        disable_click_to_close = false;
        ignore_mouse = false;
        force_keyboard_focus = true;
        hotreload_theme = true;

        activation_mode = {
          disabled = false;
          labels = "qwertyuiopasdfghjklzxcvbnm";
          use_alt = false;
          use_f_keys = false;
        };

        keys = {
          activation_modifiers = {
            keep_open = "shift";
            alternate = "alt";
          };
        };

        search = {
          placeholder = "Search...";
          resume_last_query = true;
        };

        list = {
          max_entries = 50;
        };

        builtins = {
          applications = {
            enabled = true;
            cache = true;
            context_aware = false;
            prioritize_new = false;
            show_generic = true;
            launch_prefix = lib.mkIf (osConfig.programs.uwsm.enable or false) "uwsm app -- ";
            actions = {
              enabled = true;
              hide_category = false;
              hide_without_query = false;
            };
          };

          calc = {
            enabled = true;
          };

          runner = {
            enabled = true;
            excludes = [
              "*.tmp"
              "*.bak"
            ];
            includes = [
              "*.sh"
              "*.py"
            ];
            generic_entry = true;
            use_fd = true;
          };

          websearch = {
            enabled = true;
            entries = [
              {
                name = "Google";
                url = "https://google.com/search?q={}";
                prefix = "g";
                switcher_only = false;
              }
              {
                name = "DuckDuckGo";
                url = "https://duckduckgo.com/?q={}";
                prefix = "ddg";
                switcher_only = false;
              }
              {
                name = "GitHub";
                url = "https://github.com/search?q={}";
                prefix = "gh";
                switcher_only = false;
              }
            ];
          };

          clipboard = {
            enabled = true;
            prefix = ":";
            max_entries = 50;
            avoid_line_breaks = true;
            image_height = 200;
            always_put_new_on_top = false;
          };

          finder = {
            enabled = true;
            prefix = "/";
            use_fd = true;
            ignore_gitignore = false;
            concurrency = 4;
            preview_images = true;
          };

          symbols = {
            enabled = true;
            prefix = ".";
          };

          emojis = {
            enabled = true;
            prefix = "emoji";
            show_unqualified = false;
          };

        }
        // lib.optionalAttrs config.wayland.windowManager.hyprland.enable {
          hyprland = {
            enabled = true;
            path = "${config.xdg.configHome}/hypr/hyprland.conf";
          };
        };

      };

      theme = {
        name = "khanelinix";
        layout = {
          window = {
            width = 1000;
            height = 600;
          };
        };
        style = /* Css */ ''
          * {
            transition: 200ms ease;
            font-family: MonaspaceNeon NF;
            font-size: 1.3rem;
          }

          #window,
          #match,
          #entry,
          #plugin,
          #main {
            background: transparent;
          }

          #match:selected {
            background: rgba(203, 166, 247, 0.7);
          }

          #match {
            padding: 3px;
            border-radius: 16px;
          }

          #entry,
          #plugin:hover {
            border-radius: 16px;
          }

          box#main {
            background: rgba(30, 30, 46, 1);
            border: 2px solid #494d64;
            border-radius: 16px;
            padding: 8px;
          }
        '';
      };
    };
  };
}
