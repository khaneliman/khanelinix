{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.editors.neovim;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.khanelinix.programs.terminal.editors.neovim = {
    enable = mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = mkIf cfg.default "nvim";
      };
    };

    programs.nixvim = {
      enable = true;

      defaultEditor = true;

      viAlias = true;
      vimAlias = true;

      luaLoader.enable = true;

      # Highlight and remove extra white spaces
      highlight.ExtraWhitespace.bg = "red";
      match.ExtraWhitespace = "\\s\\+$";

      colorschemes.catppuccin.enable = true;
    };

    sops.secrets = {
      wakatime = {
        sopsFile = ../../../../../../secrets/khaneliman/default.yaml;
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
