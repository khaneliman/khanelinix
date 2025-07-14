{
  config,
  lib,

  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.zellij;

  zns = "zellij -s $(basename $(pwd)) options --default-cwd $(pwd)";
  zas = "zellij a $(basename $(pwd))";
  zo = ''
    session_name=$(basename "$(pwd)")

    zellij attach --create "$session_name" options --default-cwd "$(pwd)"
  '';
in
{
  imports = [
    ./keybinds.nix
    ./layouts/dev.nix
    ./layouts/system.nix
  ];

  options.khanelinix.programs.terminal.tools.zellij = {
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
          # clipboard provider
          copy_command =
            if pkgs.stdenv.hostPlatform.isLinux && (osConfig.khanelinix.archetypes.wsl.enable or false) then
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
        };
      };
    };
  };
}
