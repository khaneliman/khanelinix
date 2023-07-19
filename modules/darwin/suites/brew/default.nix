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
      # dex2jar
      # dns2tcp
      # iproute2
      # jpeg
      # libdnet
      # lua
      # luajit
      # screenresolution
      # sfnt2woff
      # sfnt2woff-zopfli
      # wtfutil
      # xdotool
      # zsh-autosuggestions
      # zsh-completions
      # zsh-syntax-highlighting
      # lua54Packages.lua
      bash-completion
      calcurse
      cask
      dooit
      duti
      ffmpeg
      gawk
      gsl
      gtk-vnc
      gtk3
      gtksourceview4
      haskellPackages.sfnt2woff
      # ifstat-legacy
      imagemagick
      intltool
      jrnl
      keychain
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
      lolcat
      mas
      moreutils
      nb
      ncdu
      nmap
      openssh
      pngcheck
      pv
      qemu
      rlwrap
      speedtest-cli
      spice-gtk
      spicetify-cli
      spotify-tui
      ssh-copy-id
      terminal-notifier
      vbindiff
      vte
      wego
      wireguard-go
      wtf
      youtube-dl
    ];
  };
}
