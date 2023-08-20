{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.shell.bash;
in
{
  options.khanelinix.system.shell.bash = with types; {
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
