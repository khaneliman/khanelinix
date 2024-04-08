{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    xdg.configFile.wgetrc.text = "";

    khanelinix = {
      apps = {
        firefox = enabled;
      };

      cli-apps = {
        bottom = enabled;
        btop = enabled;
        fastfetch = enabled;
        tmux = enabled;
        yazi = enabled;
      };

      desktop = {
        addons = {
          kitty = enabled;
          gtk.enable = pkgs.stdenv.isLinux;
          qt.enable = pkgs.stdenv.isLinux;
          wezterm = enabled;
        };

        theme = enabled;
      };

      services = {
        # TODO: reenable after fixed
        # udiskie.enable = pkgs.stdenv.isLinux;
      };

      security = {
        # gpg = enabled;
      };

      system = {
        shell = {
          bash = enabled;
          fish = enabled;
          zsh = enabled;
        };
      };

      tools = {
        bat = enabled;
        comma = enabled;
        direnv = enabled;
        fzf = enabled;
        git = enabled;
        lsd = enabled;
        oh-my-posh = enabled;
        topgrade = enabled;
      };
    };

    programs.readline = {
      enable = true;

      extraConfig = ''
        set completion-ignore-case on
      '';
    };
  };
}
