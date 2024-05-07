{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.zellij;
in
{
  options.khanelinix.cli-apps.zellij = {
    enable = mkBoolOpt false "Whether or not to enable zellij.";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      zns = "zellij -s $(basename $(pwd)) -l dev options --default-cwd $(pwd)";
      zas = "zellij a $(basename $(pwd))";
    };

    programs.zellij = {
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
}
