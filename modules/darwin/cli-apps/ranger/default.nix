inputs @ {
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
    environment.systemPackages = with pkgs; [
      atool
      bat
      # calibre
      exiftool
      feh
      ffmpegthumbnailer
      fontforge
      glow
      # gnome-epub-thumbnailer
      highlight
      mediainfo
      mupdf
      odt2txt
      p7zip
      pandoc
      poppler_utils
      ranger
      transmission
      unrar
      unzip
      w3m
      xclip
      xlsx2csv
    ];
  };
}
