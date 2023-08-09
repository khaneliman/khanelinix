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
      # cli-apps = {
      #   ranger = enabled;
      #   tmux = enabled;
      # };

      tools = {
        git = enabled;
        oh-my-posh = enabled;
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
