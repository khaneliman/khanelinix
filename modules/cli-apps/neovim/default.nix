{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.neovim;
in
{
  options.khanelinix.cli-apps.neovim = with lib.types; {
    enable = lib.mkEnableOption "neovim";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neovim
      ripgrep
      gdu
      bottom
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
  };
}
