{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.ranger;
in
{
  options.khanelinix.cli-apps.ranger = {
    enable = mkBoolOpt false "Whether or not to enable ranger.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ranger

      # scope dependenices
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
