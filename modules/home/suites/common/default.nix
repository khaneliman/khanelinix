{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.common;
  isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;
in
{
  options.khanelinix.suites.common = {
    enable = lib.mkEnableOption "common configuration";
  };

  config = mkIf cfg.enable {
    home = {
      # Silence login messages in shells
      file = {
        ".hushlogin".text = "";
      };

      sessionVariables = {
        LESSHISTFILE = "${config.xdg.cacheHome}/less.history";
        WGETRC = "${config.xdg.configHome}/wgetrc";
      };

      shellAliases = {
        nixcfg = "nvim ${config.home.homeDirectory}/khanelinix/flake.nix";
        # Closure size checking aliases
        ncs-sys = ''f(){ nix build ".#nixosConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#nixosConfigurations.$1.config.system.build.toplevel.outPath") | tail -1; }; f'';
        ncs-darwin = ''f(){ nix build ".#darwinConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#darwinConfigurations.$1.config.system.build.toplevel.outPath") | tail -1; }; f'';
        ncs-home = ''f(){ nix build ".#homeConfigurations.$1.activationPackage" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#homeConfigurations.$1.activationPackage.outPath") | tail -1; }; f'';
        ndu = "nix-du -s=200MB | dot -Tsvg > store.svg ${
          lib.optionalString (!isWSL)
            "&& ${if pkgs.stdenv.hostPlatform.isDarwin then "open" else "xdg-open"} store.svg"
        }";
      };
    };

    home.packages =
      with pkgs;
      [
        # colorscript outputs
        dwt1-shell-color-scripts
        ncdu
        # NOTE: Typing test
        # smassh
        toilet
        tree
        wikiman
        # Visualize nix store
        nix-du
        graphviz
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pngpaste
      ];

    khanelinix = {
      programs = {
        terminal = {
          emulators = {
            kitty.enable = mkDefault (!isWSL);
          };

          shell = {
            bash = mkDefault enabled;
            # FIXME: nushell broken darwin
            nushell.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
            zsh = mkDefault enabled;
          };

          tools = {
            atuin = mkDefault enabled;
            bat = mkDefault enabled;
            btop = mkDefault enabled;
            carapace = mkDefault enabled;
            comma = mkDefault enabled;
            dircolors = mkDefault enabled;
            direnv = mkDefault enabled;
            eza = mkDefault enabled;
            fastfetch = mkDefault enabled;
            fzf = mkDefault enabled;
            git = mkDefault enabled;
            glxinfo.enable = mkDefault (pkgs.stdenv.hostPlatform.isLinux && !isWSL);
            infat.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
            jq = mkDefault enabled;
            navi = mkDefault enabled;
            nix-search-tv = mkDefault enabled;
            nh = mkDefault enabled;
            oh-my-posh = mkDefault enabled;
            pay-respects = mkDefault enabled;
            ripgrep = mkDefault enabled;
            television = mkDefault enabled;
            tray-tui.enable = mkDefault (pkgs.stdenv.hostPlatform.isLinux && !isWSL);
            topgrade = mkDefault enabled;
            yazi = mkDefault enabled;
            zellij = mkDefault enabled;
            zoxide = mkDefault enabled;
          };
        };
      };

      services = {
        # easyeffects.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        udiskie.enable = mkDefault (pkgs.stdenv.hostPlatform.isLinux && !isWSL);
        # ssh-agent.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        tray.enable = mkDefault (pkgs.stdenv.hostPlatform.isLinux && !isWSL);
      };

      system.input.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isDarwin;
    };

    programs = {
      readline = {
        enable = mkDefault true;

        extraConfig = ''
          set completion-ignore-case on
        '';
      };
    };

    xdg.configFile.wgetrc.text = "";
  };
}
