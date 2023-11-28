{ config
, lib
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf getExe;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) astronvim-config lazyvim-config lunarvim-config neovim-config;

  cfg = config.khanelinix.cli-apps.neovim;

  lsp = with pkgs; [
    binwalk
    ccls
    clang-tools
    cmake
    cmocka
    efm-langserver
    eslint_d
    gnumake
    llvm
    luajitPackages.luacheck
    luarocks
    shellcheck
    shfmt
    xmlformat
  ];
in
{
  options.khanelinix.cli-apps.neovim = {
    enable = mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        DOTNET_ROOT = "${pkgs.dotnet-sdk_7}";
        EDITOR = mkIf cfg.default "nvim";
      };

      shellAliases = {
        astronvim = "NVIM_APPNAME=astronvim nvim";
        lazyvim = "NVIM_APPNAME=lazyvim nvim";
        lunarvim = "NVIM_APPNAME=lunarvim nvim";
      };
    };

    programs.neovim = {
      enable = true;
      defaultEditor = cfg.default;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withPython3 = true;
      withRuby = true;

      extraPackages = with pkgs; [
        bottom
        curl
        deno
        dotnet-sdk_7
        fzf
        gcc
        gdu
        gnumake
        gzip
        jdk17
        lazygit
        less
        ripgrep
        tree-sitter
        unzip
        wget
      ] ++ lsp
      ++ lib.optional stdenv.isLinux webkitgtk;

      extraPython3Packages = ps: [ ps.pip ];
    };

    xdg.configFile = {
      "astronvim" = {
        onChange = "NVIM_APPNAME=astronvim ${getExe pkgs.neovim} --headless \"+Lazy! sync\" +qa";
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
        onChange = "NVIM_APPNAME=lazyvim ${getExe pkgs.neovim} --headless \"+Lazy! sync\" +qa";
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
        onChange = "NVIM_APPNAME=lunarvim ${getExe pkgs.neovim} --headless \"+Lazy! sync\" +qa";
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
      # TODO: Convert to custom nixos neovim config 
      "nvim" = {
        onChange = "${getExe pkgs.neovim} --headless \"+Lazy! sync\" +qa";
        source = lib.cleanSourceWith {
          filter = name: _type:
            let
              baseName = baseNameOf (toString name);
            in
            "lazy-lock.json" != baseName;
          src = lib.cleanSource neovim-config;
        };
        recursive = true;
      };
    };
  };
}
