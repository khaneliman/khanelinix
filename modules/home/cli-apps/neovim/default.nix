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
      sessionVariables = {
        PAGER = "less";
        MANPAGER = "less";
        NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      };
    };

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      extraPackages = with pkgs; [
        bottom
        curl
        deno
        gdu
        gzip
        lazygit
        less
        ripgrep
        unzip
        wget
      ] ++ lib.optional stdenv.isLinux webkitgtk;
    };

    xdg.configFile = with inputs; {
      "nvim" = {
        onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
        source = astronvim;
      };
      "astronvim/lua/user" = {
        source = astronvim-user;
      };
    };
  };
}
