{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.neovim;
  user = config.users.users.${config.khanelinix.user.name};
in {
  options.khanelinix.cli-apps.neovim = with lib.types; {
    enable = lib.mkEnableOption "neovim";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neovim
      ripgrep
      gdu
      bottom
      deno
      webkitgtk
    ];

    environment.variables = {
      PAGER = "less";
      MANPAGER = "less";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      EDITOR = "nvim";
    };

    khanelinix.home = with pkgs; {
      configFile = with inputs; {
        # "nvim/".source = inputs.dotfiles.outPath + "/dots/shared/home/.config/nvim";
        nvim = {
          onChange = "${neovim}/bin/nvim --headless +quitall";
          source = astronvim;
        };
        # "astronvim/lua/user/".source = inputs.dotfiles.outPath + "/dots/shared/home/.config/astronvim/lua/user";
        "astronvim/lua/user" = {
          source = astronvim-user;
        };
      };

      extraOptions = {
        # Use Neovim for Git diffs.
        programs.zsh.shellAliases.vimdiff = "nvim -d";
        programs.bash.shellAliases.vimdiff = "nvim -d";
        programs.fish.shellAliases.vimdiff = "nvim -d";
        home.shellAliases = {
          vim = "nvim";
        };
      };
    };

    # system.userActivationScripts = {
    #   postInstall = ''
    #     echo "Running deno install"
    #     source ${config.system.build.setEnvironment}
    #     cd ${user.name}/.local/share/nvim/lazy/peek.nvim/ && deno task build:debug
    #   '';
    # };
  };
}
