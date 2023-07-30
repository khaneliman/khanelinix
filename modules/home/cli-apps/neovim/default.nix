{ lib
, config
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.cli-apps.neovim;
in
{
  options.khanelinix.cli-apps.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        less
        neovim
      ];

      sessionVariables = {
        PAGER = "less";
        MANPAGER = "less";
        NPM_CONFIG_PREFIX = "$HOME/.npm-global";
        EDITOR = "nvim";
      };

      shellAliases = {
        vimdiff = "nvim -d";
        vim = "nvim";
      };
    };

    xdg.configFile = with inputs; {
      # "nvim/".source = inputs.dotfiles.outPath + "/dots/shared/home/.config/nvim";
      nvim = {
        onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
        source = astronvim;
      };
      # "astronvim/lua/user/".source = inputs.dotfiles.outPath + "/dots/shared/home/.config/astronvim/lua/user";
      "astronvim/lua/user" = {
        source = astronvim-user;
      };
    };
  };
}
