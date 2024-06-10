{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.common;
in
{
  options.${namespace}.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      nixcfg = "nvim ~/${namespace}/flake.nix";
    };

    home.packages =
      with pkgs;
      lib.optionals pkgs.stdenv.isLinux [
        kdePackages.gwenview
        kdePackages.ark
      ];

    khanelinix = {
      programs = {
        graphical = {
          browsers = {
            firefox = enabled;
          };
        };

        terminal = {
          emulators = {
            alacritty = enabled;
            foot.enable = pkgs.stdenv.isLinux;
            kitty = enabled;
            warp = enabled;
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
            jq = enabled;
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
      };

      services = {
        # easyeffects.enable = pkgs.stdenv.isLinux;
        udiskie.enable = pkgs.stdenv.isLinux;
        tray.enable = pkgs.stdenv.isLinux;
      };

      theme = {
        gtk.enable = pkgs.stdenv.isLinux;
        qt.enable = pkgs.stdenv.isLinux;
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
