{ config
, lib
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) astronvim-config lazyvim-config lunarvim-config nixvim;

  cfg = config.khanelinix.cli-apps.neovim;
in
{
  imports = [
    nixvim.homeManagerModules.nixvim
  ] ++ lib.snowfall.fs.get-non-default-nix-files ./.;

  options.khanelinix.cli-apps.neovim = {
    enable = mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
        EDITOR = mkIf cfg.default "nvim";
      };

      shellAliases = {
        astronvim = "NVIM_APPNAME=astronvim nvim";
        lazyvim = "NVIM_APPNAME=lazyvim nvim";
        lunarvim = "NVIM_APPNAME=lunarvim nvim";
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
      plugins.lightline.enable = true;

      # extraConfigLua = '''';
      extraPlugins = with pkgs.vimPlugins; [
        vim-wakatime
      ];

      extraConfigLuaPre = /* lua */ ''
        function bool2str(bool) return bool and "on" or "off" end
      '';
    };

    # TODO: setup onchange to either be after sops-nix or not load wakatime in headless
    xdg.configFile = {
      "astronvim" = {
        # onChange = "NVIM_APPNAME=astronvim ${getExe pkgs.neovim} --headless \"+Lazy! sync\" +qa";
        source = lib.cleanSourceWith {
          filter = name: _type:
            let
              baseName = baseNameOf (toString name);
            in
            "lazy-lock.json" != baseName;
          src = lib.cleanSource astronvim-config;
        };
        recursive = true;
      };
      "lazyvim" = {
        # onChange = "NVIM_APPNAME=lazyvim ${getExe pkgs.neovim} --headless \"+Lazy! sync\" +qa";
        source = lib.cleanSourceWith {
          filter = name: _type:
            let
              baseName = baseNameOf (toString name);
            in
            "lazy-lock.json" != baseName;
          src = lib.cleanSource lazyvim-config;
        };
        recursive = true;
      };
      "lunarvim" = {
        # onChange = "NVIM_APPNAME=lunarvim ${getExe pkgs.neovim} --headless \"+Lazy! sync\" +qa";
        source = lib.cleanSourceWith {
          filter = name: _type:
            let
              baseName = baseNameOf (toString name);
            in
            "lazy-lock.json" != baseName;
          src = lib.cleanSource lunarvim-config;
        };
        recursive = true;
      };
    };
  };
}
