{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.editors.neovim;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files-recursive ./.;

  options.${namespace}.programs.terminal.editors.neovim = {
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
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.wakatime.cfg";
      };
    };
  };
}
