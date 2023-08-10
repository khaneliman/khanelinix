{ options
, config
, lib
, inputs
, pkgs
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

    xdg.configFile = {
      "fish/themes".source = fishBasePath + "themes/";
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

    programs.fish = {
      enable = true;
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

        # Disable greeting
        set fish_greeting 

        # Fetch on terminal open
        if status is-interactive
            if [ "$TMUX" = "" ];
                command -v tmux && tmux
            end

            fastfetch 
        end
      '';
      plugins = [
        # Enable a plugin (here grc for colorized command output) from nixpkgs
        # { name = "grc"; src = pkgs.fishPlugins.grc.src; }
        {
          name = "autopair";
          inherit (pkgs.fishPlugins.autopair) src;
        }
        {
          name = "done";
          inherit (pkgs.fishPlugins.done) src;
        }
        {
          name = "fzf-fish";
          inherit (pkgs.fishPlugins.fzf-fish) src;
        }
        {
          name = "forgit";
          inherit (pkgs.fishPlugins.forgit) src;
        }
        {
          name = "tide";
          inherit (pkgs.fishPlugins.tide) src;
        }
        {
          name = "sponge";
          inherit (pkgs.fishPlugins.sponge) src;
        }
        {
          name = "wakatime";
          inherit (pkgs.fishPlugins.wakatime-fish) src;
        }
        {
          name = "z";
          inherit (pkgs.fishPlugins.z) src;
        }
      ];
    };
  };
}

