{ lib
, config
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.neovim;
in
{
  options.khanelinix.cli-apps.neovim = {
    enable = mkEnableOption "Neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = mkIf cfg.default "nvim";
      };
    };

    programs.neovim = {
      enable = true;
      defaultEditor = cfg.default;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      extraPackages = with pkgs; [
        bottom
        curl
        deno
        fzf
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
