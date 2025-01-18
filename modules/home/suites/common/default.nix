{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    home = {
      # Silence login messages in shells
      file = {
        ".hushlogin".text = "";
      };

      shellAliases = {
        nixcfg = "nvim ~/khanelinix/flake.nix";
      };
    };

    home.packages = with pkgs; [
      ncdu
      smassh
      toilet
      tree
    ];

    khanelinix = {
      programs = {
        graphical = {
          browsers = {
            firefox = mkDefault enabled;
          };
        };

        terminal = {
          emulators = {
            alacritty = mkDefault enabled;
            foot.enable = pkgs.stdenv.isLinux;
            ghostty = mkDefault enabled;
            kitty = mkDefault enabled;
            warp = mkDefault enabled;
            wezterm = mkDefault enabled;
          };

          shell = {
            bash = mkDefault enabled;
            nushell = mkDefault enabled;
            zsh = mkDefault enabled;
          };

          tools = {
            bat = mkDefault enabled;
            bottom = mkDefault enabled;
            btop = mkDefault enabled;
            carapace = mkDefault enabled;
            colorls = mkDefault enabled;
            comma = mkDefault enabled;
            direnv = mkDefault enabled;
            eza = mkDefault enabled;
            fastfetch = mkDefault enabled;
            fzf = mkDefault enabled;
            fup-repl = mkDefault enabled;
            git = mkDefault enabled;
            glxinfo.enable = mkDefault pkgs.stdenv.isLinux;
            jq = mkDefault enabled;
            jujutsu = mkDefault enabled;
            lsd = mkDefault enabled;
            oh-my-posh = mkDefault enabled;
            ripgrep = mkDefault enabled;
            tmux = mkDefault enabled;
            topgrade = mkDefault enabled;
            yazi = mkDefault enabled;
            zellij = mkDefault enabled;
            zoxide = mkDefault enabled;
          };
        };
      };

      services = {
        # easyeffects.enable = mkDefault pkgs.stdenv.isLinux;
        udiskie.enable = mkDefault pkgs.stdenv.isLinux;
        # ssh-agent.enable = mkDefault pkgs.stdenv.isLinux;
        tray.enable = mkDefault pkgs.stdenv.isLinux;
      };

      theme = {
        gtk.enable = mkDefault pkgs.stdenv.isLinux;
        qt.enable = mkDefault pkgs.stdenv.isLinux;
      };
    };

    programs.readline = {
      enable = mkDefault true;

      extraConfig = ''
        set completion-ignore-case on
      '';
    };

    xdg.configFile.wgetrc.text = "";
  };
}
