{ options
, config
, lib
, pkgs
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

      extraOptions = {
        programs.fish = {
          enable = true;
          loginShellInit = ''
          '';
          interactiveShellInit = ''
            fish_add_path "$HOME/.local/bin"

            if [ -f "$HOME"/.aliases ];
              source ~/.aliases
            end

            if [ $(command -v hyprctl) ];
                # Hyprland logs 
                alias hl='cat /tmp/hypr/$(lsd -t /tmp/hypr/ | head -n 1)/hyprland.log'
                alias hl1='cat /tmp/hypr/$(lsd -t -r /tmp/hypr/ | head -n 2 | tail -n 1)/hyprland.log'
            end

            set fish_greeting # Disable greeting
            fastfetch
          '';
          plugins = [
            # Enable a plugin (here grc for colorized command output) from nixpkgs
            # { name = "grc"; src = pkgs.fishPlugins.grc.src; }
            { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
            { name = "done"; src = pkgs.fishPlugins.done.src; }
            { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
            { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }
            { name = "tide"; src = pkgs.fishPlugins.tide.src; }
            { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }
            { name = "wakatime"; src = pkgs.fishPlugins.wakatime-fish.src; }
            { name = "z"; src = pkgs.fishPlugins.z.src; }
            # Manually packaging and enable a plugin
            # {
            #   name = "fisher";
            #   src = pkgs.fetchFromGitHub {
            #     owner = "jorgebucaran";
            #     repo = "fisher";
            #     rev = "4.4.3";
            #     hash = "sha256-q9Yi6ZlHNFnPN05RpO+u4B5wNR1O3JGIn2AJ3AEl4xs=";
            #   };
            # }
          ];
        };
      };
    };
  };
}
