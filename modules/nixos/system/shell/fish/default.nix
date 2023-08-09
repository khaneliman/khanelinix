{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.shell.fish;
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
