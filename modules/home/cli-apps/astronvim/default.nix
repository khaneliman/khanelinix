{ lib
, config
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf getExe;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) neovim-config;

  cfg = config.khanelinix.cli-apps.astronvim;

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
  options.khanelinix.cli-apps.astronvim = {
    enable = mkEnableOption "Astronvim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        DOTNET_ROOT = "${pkgs.dotnet-sdk_7}";
        EDITOR = mkIf cfg.default "nvim";
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
        fzf
        gdu
        gzip
        lazygit
        gnumake
        less
        ripgrep
        unzip
        wget
        gcc
        dotnet-sdk_7
      ] ++ lsp
      ++ lib.optional stdenv.isLinux webkitgtk;
    };

    # TODO: Convert to custom nixos neovim config 
    xdg.configFile = {
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
