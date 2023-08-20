{ config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      cli-apps = {
        # ranger = enabled;
        btop = enabled;
        fastfetch = enabled;
        tmux = enabled;
      };

      desktop = {
        addons = {
          kitty = enabled;
        };
      };

      tools = {
        bat = enabled;
        direnv = enabled;
        git = enabled;
        lsd = enabled;
        oh-my-posh = enabled;
        topgrade = enabled;
      };

      system = {
        shell = {
          bash = enabled;
          fish = enabled;
          zsh = enabled;
        };
      };

      security = {
        # gpg = enabled;
      };
    };
  };
}
