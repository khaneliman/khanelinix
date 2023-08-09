{ options
, config
, lib
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.shell.fish;
  fishBasePath = inputs.dotfiles.outPath + "/dots/shared/home/.config/fish/";
in
{
  options.khanelinix.system.shell.fish = with types; {
    enable = mkBoolOpt false "Whether to enable fish.";
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      loginShellInit = ''
          '';
      interactiveShellInit = ''
        fish_add_path "$HOME/.local/bin"

        if [ -f "$HOME"/.aliases ];
          source ~/.aliases
        end

        set fish_greeting # Disable greeting
        fastfetch
      '';
    };

    khanelinix.home = {
      configFile = {
        "fish/themes".source = fishBasePath + "themes/";
        "fish/conf.d/environment_variables.fish".source = fishBasePath + "conf.d/environment_variables.fish";
        "fish/conf.d/fish_variables.fish".source = fishBasePath + "conf.d/fish_variables.fish";
        "fish/functions/bak.fish".source = fishBasePath + "functions/bak.fish";
        "fish/functions/cd.fish".source = fishBasePath + "functions/cd.fish";
        "fish/functions/clear.fish".source = fishBasePath + "functions/clear.fish";
        "fish/functions/ex.fish".source = fishBasePath + "functions/ex.fish";
        "fish/functions/git.fish".source = fishBasePath + "functions/git.fish";
        "fish/functions/load_ssh.fish".source = fishBasePath + "functions/load_ssh.fish";
        "fish/functions/mkcd.fish".source = fishBasePath + "functions/mkcd.fish";
        "fish/functions/mvcd.fish".source = fishBasePath + "functions/mvcd.fish";
        "fish/functions/ranger.fish".source = fishBasePath + "functions/ranger.fish";
      };
    };
  };
}

