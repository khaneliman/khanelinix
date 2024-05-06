{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.neovim;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.khanelinix.cli-apps.neovim = {
    enable = mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        # TODO: why was this set ?
        # DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
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

      extraConfigLuaPre = # lua
        ''
          function bool2str(bool) return bool and "on" or "off" end

          require("aerial").setup()
        '';
    };

    sops.secrets = {
      wakatime = {
        sopsFile = ../../../../secrets/khaneliman/default.yaml;
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
