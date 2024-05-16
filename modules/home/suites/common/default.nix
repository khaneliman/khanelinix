{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      nixcfg = "nvim ~/khanelinix/flake.nix";
    };

    khanelinix = {
      desktop = {
        theme = enabled;
      };

      programs = {
        graphical = {
          browsers = {
            firefox = enabled;
          };
        };

        terminal = {
          emulators = {
            kitty = enabled;
            wezterm = enabled;
          };

          shell = {
            bash = enabled;
            fish = enabled;
            zsh = enabled;
          };

          tools = {
            bat = enabled;
            bottom = enabled;
            btop = enabled;
            colorls = enabled;
            comma = enabled;
            direnv = enabled;
            eza = enabled;
            fastfetch = enabled;
            fzf = enabled;
            fup-repl = enabled;
            git = enabled;
            glxinfo.enable = pkgs.stdenv.isLinux;
            lsd = enabled;
            oh-my-posh = enabled;
            ripgrep = enabled;
            tmux = enabled;
            topgrade = enabled;
            yazi = enabled;
            zellij = enabled;
            zoxide = enabled;
          };
        };

        theme = {
          gtk.enable = pkgs.stdenv.isLinux;
          qt.enable = pkgs.stdenv.isLinux;
        };
      };

      services = {
        # easyeffects.enable = pkgs.stdenv.isLinux;
        udiskie.enable = pkgs.stdenv.isLinux;
        tray.enable = pkgs.stdenv.isLinux;
      };
    };

    programs.readline = {
      enable = true;

      extraConfig = ''
        set completion-ignore-case on
      '';
    };

    xdg.configFile.wgetrc.text = "";
  };
}
