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
      prepend_rules = archiveRules ++ [
        {
          url = "*/";
          use = [
            "edit"
            "open"
            "reveal"
          ];
        }
      ];

      append_rules = [
        {
          url = "*";
          use = [
            "edit"
            "open"
            "reveal"
          ];
        }
      ];
    };
}
