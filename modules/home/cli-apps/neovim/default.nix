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

    # TODO: Convert to custom nixos neovim config 
    xdg.configFile = {
      "astronvim" = {
        onChange = "${getExe pkgs.neovim} --headless +quitall";
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
        onChange = "${getExe pkgs.neovim} --headless +quitall";
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
        onChange = "${getExe pkgs.neovim} --headless +quitall";
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
      "nvim" = {
        onChange = "${getExe pkgs.neovim} --headless +quitall";
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
