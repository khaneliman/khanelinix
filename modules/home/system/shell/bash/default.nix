{ options
, config
, lib
, inputs
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
        # Source functions
        if [ -f "$HOME"/.functions ]; then
        	source "$HOME"/.functions
        fi
        
        if [ "$TMUX" = "" ]; then command -v tmux && tmux; fi

        fastfetch
      '';
    };

    home.file = with inputs; {
      ".functions".source = dotfiles.outPath + "/dots/shared/home/.functions";
    };
  };
}
