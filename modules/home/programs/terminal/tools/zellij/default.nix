{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.zellij;

  zns = "zellij -s $(basename $(pwd)) -l dev options --default-cwd $(pwd)";
  zas = "zellij a $(basename $(pwd))";
  zo = ''
    session_name=$(basename "$(pwd)")

    zellij --layout dev  attach --create "$session_name" options --default-cwd "$(pwd)"
  '';
in
{
  options.khanelinix.programs.terminal.tools.zellij = {
    enable = mkBoolOpt false "Whether or not to enable zellij.";
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

        # These enable auto starting
        # enableBashIntegration = true;
        # enableFishIntegration = true;
        # enableZshIntegration = true;

        settings = {
          # custom defined layouts
          layout_dir = "${./layouts}";

          # clipboard provider
          copy_command =
            if pkgs.stdenv.isLinux then
              "wl-copy"
            else if pkgs.stdenv.isDarwin then
              "pbcopy"
            else
              "";

          auto_layouts = true;

          default_layout = "system"; # or compact
          default_mode = "locked";
          support_kitty_keyboard_protocol = false;

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
