{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.brew;
in {
  options.khanelinix.suites.brew = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable brew configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
        homebrew = enabled;
      };
    };

    environment.systemPackages = with pkgs; [
      # brightnessctl
      # cifer
      # clang-format
      # dex2jar
      # dns2tcp
      # iproute2
      # jpeg
      # libdnet
      # lua
      # luajit
      # pnpm
      # screenresolution
      # sfnt2woff
      # sfnt2woff-zopfli
      # switchaudio-osx
      # wtfutil
      # xdotool
      # zsh-autosuggestions
      # zsh-completions
      # zsh-syntax-highlighting
      # lua54Packages.lua
      ack
      act
      armadillo
      atool
      bash-completion
      bat
      bear
      bfg-repo-cleaner
      binutils
      binwalk
      boost
      bottom
      btop
      calcurse
      cask
      ccls
      clang-tools
      cmake
      cmocka
      coreutils
      curl
      deno
      direnv
      docutils
      dooit
      duti
      efm-langserver
      eslint_d
      exa
      fasd
      fd
      feh
      ffmpeg
      findutils
      fontforge
      fzf
      gawk
      gh
      git
      git-crypt
      git-filter-repo
      git-lfs
      gitflow
      gitleaks
      gitlint
      glow
      gnugrep
      gnumake
      gnupg
      gnused
      gnutls
      gsl
      gtk-vnc
      gtk3
      gtksourceview4
      haskellPackages.sfnt2woff
      # ifstat-legacy
      imagemagick
      intltool
      jq
      jrnl
      keychain
      lazydocker
      lazygit
      libcerf
      libgit2
      libmms
      libnice
      libosinfo
      libsass
      libsoup
      libvirt
      libvirt-glib
      libxml2
      llvm
      lolcat
      lsd
      luajitPackages.luacheck
      luajit_openresty
      luarocks
      mas
      meson
      moreutils
      mysql-client
      nb
      ncdu
      neovide
      nmap
      oh-my-posh
      onefetch
      openssh
      p7zip
      perl
      php
      pigz
      pngcheck
      pv
      qemu
      ranger
      rapidjson
      rename
      rlwrap
      rustup
      shellcheck
      shfmt
      socat
      speedtest-cli
      spice-gtk
      spicetify-cli
      spotify-tui
      ssh-copy-id
      swig
      terminal-notifier
      tldr
      tmux
      toilet
      topgrade
      trash-cli
      tree
      vbindiff
      vte
      wego
      wget
      wireguard-go
      wtf
      xclip
      xmlformat
      xpdf
      yasm
      youtube-dl
    ];
  };
}
