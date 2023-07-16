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
    environment.systemPackages = with pkgs; [
      ack
      act
      armadillo
      atool
      bat
      bash-completion
      bear
      bfg-repo-cleaner
      binutils
      binwalk
      # blueutil
      boost
      bottom
      haskellPackages.sfnt2woff
      # sfnt2woff
      # sfnt2woff-zopfli
      # brew-cask-completion
      # brightness
      # brightnessctl
      btop
      calcurse
      cask
      ccls
      # cifer
      # clang-format
      clang-tools
      cmake
      cmocka
      deno
      # dex2jar
      direnv
      # dns2tcp
      docutils
      dooit
      duti
      efm-langserver
      eslint_d
      exa
      fasd
      # fastfetch
      fd
      feh
      sketchybar
      findutils
      # fisher
      fontforge
      fzf
      gawk
      gh
      git
      git-crypt
      git-filter-repo
      # git-flow
      gitflow
      git-lfs
      gitleaks
      gitlint
      glow
      gnupg
      gsl
      gtk-vnc
      gtksourceview4
      # ical-buddy
      # iproute2
      imagemagick
      intltool
      # jpeg
      jq
      jrnl
      keychain
      spicetify-cli
      skhd
      yabai
      lazydocker
      lazygit
      libcerf
      # libdnet
      libgit2
      libmms
      libnice
      libosinfo
      libsass
      libsoup
      libvirt-glib
      libxml2
      llvm
      lolcat
      lsd
      # lua
      # luajit
      luajitPackages.luacheck
      # luacheck
      luajit_openresty
      luarocks
      # make
      gnumake
      mas
      meson
      moreutils
      mysql-client
      nb
      ncdu
      neovide
      oh-my-posh
      onefetch
      openssh
      perl
      php
      pigz
      pngcheck
      # pnpm
      nodePackages.pnpm
      nodePackages.prettier
      pv
      qemu
      ranger
      rapidjson
      rename
      rlwrap
      rustup
      # screenresolution
      shellcheck
      shfmt
      socat
      speedtest-cli
      spice-gtk
      spotify-tui
      ssh-copy-id
      swig
      # switchaudio-osx
      terminal-notifier
      tldr
      tmux
      toilet
      topgrade
      trash-cli
      tree
      vbindiff
      # vte3
      vte
      wego
      wget
      wireguard-go
      # wtfutil
      wtf
      xclip
      # xdotool
      xmlformat
      xpdf
      yasm
      youtube-dl
      # zsh-autosuggestions
      # zsh-completions
      # zsh-syntax-highlighting
    ];
  };
}
