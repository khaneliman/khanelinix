{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.system.shell.bash;
in
{
  options.khanelinix.system.shell.bash = {
    enable = mkBoolOpt false "Whether to enable bash.";
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;

      initExtra = ''
        if [ "$TMUX" = "" ]; then command -v tmux && tmux; fi

        fastfetch
      '';
    };
  };
}
