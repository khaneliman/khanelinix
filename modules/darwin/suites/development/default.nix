{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.development;
in {
  options.khanelinix.suites.development = with types; {
    enable =
      mkBoolOpt false
      "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      tools = {
        # at = enabled;
        # direnv = enabled;
        # go = enabled;
        # http = enabled;
        # k8s = enabled;
        node = enabled;
        # titan = enabled;
        python = enabled;
        java = enabled;
      };

      # virtualisation = { podman = enabled; };
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
    ];

    homebrew = {
      enable = true;

      masApps = {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };
  };
}
