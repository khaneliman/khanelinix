{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      tools = {
        node = enabled;
        python = enabled;
        java = enabled;
      };
    };

    environment.systemPackages = with pkgs; [
      ack
      act
      armadillo
      bear
      bfg-repo-cleaner
      binutils
      binwalk
      boost
      ccls
      clang-tools
      cmake
      cmocka
      direnv
      docutils
      efm-langserver
      eslint_d
      gnumake
      gtksourceview4
      jq
      lazydocker
      llvm
      luajitPackages.luacheck
      luajit_openresty
      luarocks
      meson
      mysql-client
      neovide
      onefetch
      perl
      php
      pv
      rapidjson
      rlwrap
      rustup
      shellcheck
      shfmt
      swig
      vbindiff
      xmlformat
      yasm

      #nix
      nixpkgs-fmt
      nixpkgs-review
      nixpkgs-lint-community
      nixpkgs-hammering
    ];

    homebrew = {
      brews = [
        "brew-cask-completion"
        "jq"
        "gh"
      ];

      casks = [
        "cutter"
        "docker"
        "electron"
        "powershell"
        "visual-studio-code"
      ];

      taps = [
        "cloudflare/cloudflare"
        "earthly/earthly"
      ];

      masApps = {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };
  };
}
