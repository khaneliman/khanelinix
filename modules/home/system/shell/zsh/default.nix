{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.system.shell.zsh;
in
{
  options.khanelinix.system.shell.zsh = {
    enable = mkEnableOption "ZSH";
  };

  config = mkIf cfg.enable {
    home = {
      file = {
        ".p10k.zsh".source = ./.p10k.zsh;
      };
    };

    programs = {
      zsh = {
        enable = true;
        package = pkgs.zsh;

        completionInit = ''
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        '';

        enableAutosuggestions = true;
        enableCompletion = true;

        sessionVariables = {
          KEYTIMEOUT = 0;
        };

        syntaxHighlighting = {
          enable = true;
          package = pkgs.zsh-syntax-highlighting;
        };

        initExtra = ''
          # Use vim bindings.
          set -o vi

          # Improved vim bindings.
          source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

          fastfetch
        '';

        plugins = [
          # {
          #   name = "zsh-autocomplete";
          #   src = pkgs.zsh-autocomplete;
          # }
          {
            name = "zsh-command-time";
            src = pkgs.zsh-command-time;
          }
          {
            name = "zsh-history";
            src = pkgs.zsh-history;
          }
          {
            name = "zsh-history-to-fish";
            src = pkgs.zsh-history-to-fish;
          }
          {
            name = "zsh-navigation-tools";
            src = pkgs.zsh-navigation-tools;
          }
          {
            name = "zsh-nix-shell";
            file = "nix-shell.plugin.zsh";
            src = pkgs.zsh-nix-shell;
          }
          {
            name = "zsh-you-should-use";
            src = pkgs.zsh-you-should-use;
          }

        ];
      };
    };
  };
}
