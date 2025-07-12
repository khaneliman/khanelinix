{
  config,
  lib,
  namespace,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.zellij;

  zns = "zellij -s $(basename $(pwd)) options --default-cwd $(pwd)";
  zas = "zellij a $(basename $(pwd))";
  zo = ''
    session_name=$(basename "$(pwd)")

    zellij attach --create "$session_name" options --default-cwd "$(pwd)"
  '';
in
{
  options.${namespace}.programs.terminal.tools.zellij = {
    enable = lib.mkEnableOption "zellij";
  };

  config = mkIf cfg.enable {
    programs = {
      bash.shellAliases = {
        inherit zns zas zo;
      };

      zsh.shellAliases = {
        inherit zns zas zo;
      };

      zellij = {
        enable = true;

        settings = {
          # custom defined layouts
          layout_dir = "${./layouts}";

          # clipboard provider
          copy_command =
            if pkgs.stdenv.hostPlatform.isLinux && (osConfig.${namespace}.archetypes.wsl.enable or false) then
              "clip.exe"
            else if pkgs.stdenv.hostPlatform.isLinux then
              "wl-copy"
            else if pkgs.stdenv.hostPlatform.isDarwin then
              "pbcopy"
            else
              "";

          auto_layouts = true;

          default_layout = "dev";
          default_mode = "locked";
          support_kitty_keyboard_protocol = true;

          on_force_close = "quit";
          pane_frames = true;
          pane_viewport_serialization = true;
          scrollback_lines_to_serialize = 1000;
          session_serialization = true;

          ui.pane_frames = {
            rounded_corners = true;
            hide_session_name = true;
          };

          # load internal plugins from built-in paths
          plugins = {
            tab-bar.path = "tab-bar";
            status-bar.path = "status-bar";
            strider.path = "strider";
            compact-bar.path = "compact-bar";
          };

          theme = "catppuccin-macchiato";
          keybinds = {
            # This clears all default keybindings to start fresh.
            # _props.clear-defaults = true;

            # Keybindings for the "locked" mode (Vim's normal mode equivalent)
            locked = {
              _children = [
                # Pane Navigation using Alt + hjkl
                {
                  bind = {
                    _args = [ "Alt h" ];
                    _children = [ { MoveFocus._args = [ "Left" ]; } ];
                  };
                }
                {
                  bind = {
                    _args = [ "Alt j" ];
                    _children = [ { MoveFocus._args = [ "Down" ]; } ];
                  };
                }
                {
                  bind = {
                    _args = [ "Alt k" ];
                    _children = [ { MoveFocus._args = [ "Up" ]; } ];
                  };
                }
                {
                  bind = {
                    _args = [ "Alt l" ];
                    _children = [ { MoveFocus._args = [ "Right" ]; } ];
                  };
                }

                # Pane Management (like :split and :vsplit)
                {
                  bind = {
                    _args = [ "Alt n" ];
                    _children = [ { NewPane = { }; } ];
                  };
                } # New pane below (horizontal split)
                {
                  bind = {
                    _args = [ "Alt v" ];
                    _children = [ { NewPane._props.direction = "Right"; } ];
                  };
                } # New pane to the right (vertical split)
                {
                  bind = {
                    _args = [ "Alt x" ];
                    _children = [ { CloseFocus = { }; } ];
                  };
                } # Close focused pane
                {
                  bind = {
                    _args = [ "Alt z" ];
                    _children = [ { ToggleFocusFullscreen = { }; } ];
                  };
                } # Zoom/unzoom pane

                # Tab Management
                {
                  bind = {
                    _args = [ "Alt t" ];
                    _children = [ { NewTab = { }; } ];
                  };
                } # New tab
                {
                  bind = {
                    _args = [ "Ctrl l" ];
                    _children = [ { GoToNextTab = { }; } ];
                  };
                } # Go to next tab
                {
                  bind = {
                    _args = [ "Ctrl h" ];
                    _children = [ { GoToPreviousTab = { }; } ];
                  };
                } # Go to previous tab

                # Enter other modes
                {
                  bind = {
                    _args = [ "Alt s" ];
                    _children = [ { SwitchToMode._args = [ "Scroll" ]; } ];
                  };
                }
                {
                  bind = {
                    _args = [ "Alt r" ];
                    _children = [ { SwitchToMode._args = [ "RenamePane" ]; } ];
                  };
                }
              ];
            };

            # Keybindings for "scroll" mode (for scrolling up/down the buffer)
            scroll = {
              _children = [
                {
                  bind = {
                    _args = [
                      "j"
                      "Down"
                    ];
                    _children = [ { ScrollDown = { }; } ];
                  };
                }
                {
                  bind = {
                    _args = [
                      "k"
                      "Up"
                    ];
                    _children = [ { ScrollUp = { }; } ];
                  };
                }
                {
                  bind = {
                    _args = [
                      "q"
                      "Esc"
                    ];
                    _children = [ { SwitchToMode._args = [ "Locked" ]; } ];
                  };
                }
              ];
            };

            # Keybindings for renaming a pane
            renamepane = {
              _children = [
                {
                  bind = {
                    _args = [ "Enter" ];
                    _children = [ { SwitchToMode._args = [ "Locked" ]; } ];
                  };
                }
                {
                  bind = {
                    _args = [ "Esc" ];
                    # This demonstrates multiple actions for a single bind
                    _children = [
                      { UndoRenamePane = { }; }
                      { SwitchToMode._args = [ "Locked" ]; }
                    ];
                  };
                }
              ];
            };
          };
        };
      };
    };
  };
}
