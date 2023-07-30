{ lib
, config
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.cli-apps.zsh;
in
{
  options.khanelinix.cli-apps.zsh = {
    enable = mkEnableOption "ZSH";
  };

  config = mkIf cfg.enable {
    home = {
      file = with inputs; {
        ".zshrc".source = dotfiles.outPath + "/dots/shared/home/.zshrc";
        ".zshenv".source = dotfiles.outPath + "/dots/shared/home/.zshenv";
        ".p10k.zsh".source = dotfiles.outPath + "/dots/shared/home/.p10k.zsh";
        ".aliases".source = dotfiles.outPath + "/dots/shared/home/.aliases";
        ".functions".source = dotfiles.outPath + "/dots/shared/home/.functions";
      };
    };

    programs = {
      zsh = {
        enable = true;
        enableAutosuggestions = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;

        initExtra = ''
          # Fix an issue with tmux.
          export KEYTIMEOUT=1

          # Use vim bindings.
          set -o vi

          # Improved vim bindings.
          source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
        '';

        shellAliases = { };

        plugins = [
          {
            name = "zsh-nix-shell";
            file = "nix-shell.plugin.zsh";
            src = pkgs.fetchFromGitHub {
              owner = "chisui";
              repo = "zsh-nix-shell";
              rev = "v0.4.0";
              sha256 = "037wz9fqmx0ngcwl9az55fgkipb745rymznxnssr3rx9irb6apzg";
            };
          }
        ];
      };
    };
  };
}
