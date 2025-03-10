{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.common;
in
{
  options.${namespace}.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    home = {
      # Silence login messages in shells
      file = {
        ".hushlogin".text = "";
      };

      shellAliases = {
        nixcfg = "nvim ~/${namespace}/flake.nix";
        ndu = "nix-du -s=200MB | dot -Tsvg > store.svg && ${
          if pkgs.stdenv.hostPlatform.isDarwin then "open" else "xdg-open"
        } store.svg";
      };
    };

    home.packages =
      with pkgs;
      [
        dwt1-shell-color-scripts
        ncdu
        smassh
        toilet
        tree
        nh
        nix-du
        graphviz
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pngpaste
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
            foot.enable = pkgs.stdenv.hostPlatform.isLinux;
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
            atuin = mkDefault enabled;
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
            glxinfo.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
            jq = mkDefault enabled;
            jujutsu = mkDefault enabled;
            lsd = mkDefault enabled;
            navi = mkDefault enabled;
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
        # easyeffects.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        udiskie.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        # ssh-agent.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        tray.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
      };

      theme = {
        gtk.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        qt.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
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
