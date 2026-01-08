{
  open =
    let
      archiveExtensions = [
        "7z"
        "ace"
        "ar"
        "arc"
        "bz2"
        "cab"
        "cpio"
        "cpt"
        "deb"
        "dgc"
        "dmg"
        "gz"
        "iso"
        "jar"
        "msi"
        "pkg"
        "rar"
        "shar"
        "tar"
        "tgz"
        "xar"
        "xpi"
        "xz"
        "zip"
      ];

      generateArchiveRule = ext: {
        url = "*.${ext}";
        use = [
          "extract"
          "reveal"
        ];
      };

      archiveRules = map generateArchiveRule archiveExtensions;
    in
    {
      rules = archiveRules ++ [
        {
          url = "*.dmg";
          use = [
            "dmg"
            "reveal"
          ];
        }
        {
          url = "*/";
          use = [
            "edit"
            "open"
            "reveal"
          ];
        }
        {
          mime = "text/*";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "image/*";
          use = [
            "open"
            "reveal"
          ];
        }
        {
          mime = "video/*";
          use = [
            "play"
            "reveal"
          ];
        }
        {
          mime = "audio/*";
          use = [
            "play"
            "reveal"
          ];
        }
        {
          mime = "inode/empty";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "application/json";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "*/javascript";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "application/zip";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/gzip";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/tar";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/bzip";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/bzip2";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/7z-compressed";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/rar";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/xz";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "*";
          use = [
            "edit"
            "open"
            "reveal"
          ];
        }
      ];
    };
}
