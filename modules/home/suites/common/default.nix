{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = {
    enable =
      mkBoolOpt false
        "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    xdg.configFile.wgetrc.text = "";

    khanelinix = {
      cli-apps = {
        bottom = enabled;
        btop = enabled;
        fastfetch = enabled;
        ranger = enabled;
        tmux = enabled;
        yazi = enabled;
      };

      desktop = {
        addons = {
          kitty = enabled;
          qt.enable = pkgs.stdenv.isLinux;
          wezterm = enabled;
        };

        theme = enabled;
      };

      services = {
        udiskie.enable = pkgs.stdenv.isLinux;
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
        direnv = enabled;
        fzf = enabled;
        git = enabled;
        lsd = enabled;
        oh-my-posh = enabled;
        topgrade = enabled;
      };
    };
  };
}
