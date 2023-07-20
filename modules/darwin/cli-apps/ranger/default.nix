{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.ranger;
in {
  options.khanelinix.cli-apps.ranger = with types; {
    enable = mkBoolOpt false "Whether or not to enable ranger.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;

      brews = [
        "librsvg"
      ];

      casks = [
      ];
    };

    environment.systemPackages = with pkgs; [
      ranger

      # calibre
      # gnome-epub-thumbnailer
      atool
      bat
      catdoc
      ebook_tools
      elinks
      exiftool
      feh
      ffmpegthumbnailer
      fontforge
      glow
      highlight
      lynx
      mediainfo
      mupdf
      odt2txt
      p7zip
      pandoc
      poppler_utils
      python311Packages.pygments
      transmission
      unrar
      unzip
      w3m
      xclip
      xlsx2csv
    ];
  };
}
