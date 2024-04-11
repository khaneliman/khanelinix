{ lib, pkgs }:
{
  manager = {
    layout = [
      1
      3
      4
    ];
    linemode = "size";
    show_hidden = true;
    show_symlink = true;
    sort_by = "alphabetical";
    sort_dir_first = true;
    sort_reverse = false;
    sort_sensitive = false;
  };

  opener = {
    edit = [
      {
        run = "nvim \"$@\"";
        desc = "$EDITOR";
        block = true;
        for = "unix";
      }
      {
        run = "code \"%*\"";
        orphan = true;
        desc = "code";
        for = "windows";
      }
      {
        run = "code -w \"%*\"";
        block = true;
        desc = "code (block)";
        for = "windows";
      }
    ];
    open = [
      {
        run = "xdg-open \"$@\"";
        desc = "Open";
        for = "linux";
      }
      {
        run = "open \"$@\"";
        desc = "Open";
        for = "macos";
      }
      {
        run = "start \"\" \"%1\"";
        orphan = true;
        desc = "Open";
        for = "windows";
      }
    ];
    reveal = [
      {
        run = "open -R \"$1\"";
        desc = "Reveal";
        for = "macos";
      }
      {
        run = "explorer /select, \"%1\"";
        orphan = true;
        desc = "Reveal";
        for = "windows";
      }
      {
        run = "exiftool \"$1\"; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show EXIF";
        for = "unix";
      }
    ];
    extract = [
      {
        desc = "Extract with atool";
        run = "${lib.getExe pkgs.atool} --extract --each --subdir --quiet -- \"$@\"";
        block = true;
      }
      {
        run = "unar \"$1\"";
        desc = "Extract here";
        for = "unix";
      }
      {
        run = "unar \"%1\"";
        desc = "Extract here";
        for = "windows";
      }
    ];
    play = [
      {
        run = "mpv \"$@\"";
        orphan = true;
        for = "unix";
      }
      {
        run = "mpv \"%1\"";
        orphan = true;
        for = "windows";
      }
      {
        run = "mediainfo \"$1\"; echo \"Press enter to exit\"; read _";
        block = true;
        desc = "Show media info";
        for = "unix";
      }
    ];
  };

  open = {
    rules = [
      # TODO: iterate over list to produce attribute set
      # {
      #   name = "*.{7z,ace,ar,arc,bz2,cab,cpio,cpt,deb,dgc,dmg,gz}";
      #   use = "archive";
      # }
      # {
      #   name = "*.{iso,jar,msi,pkg,rar,shar,tar,tgz,xar,xpi,xz,zip}";
      #   use = "archive";
      # }
      {
        name = "*.7z";
        use = "extract";
      }
      {
        name = "*.zip";
        use = "extract";
      }
      {
        name = "*.gz";
        use = "extract";
      }
      {
        name = "*.xz";
        use = "extract";
      }
      {
        name = "*.tar";
        use = "extract";
      }
      {
        name = "*/";
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
        mime = "inode/x-empty";
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
        mime = "application/x-tar";
        use = [
          "extract"
          "reveal"
        ];
      }
      {
        mime = "application/x-bzip";
        use = [
          "extract"
          "reveal"
        ];
      }
      {
        mime = "application/x-bzip2";
        use = [
          "extract"
          "reveal"
        ];
      }
      {
        mime = "application/x-7z-compressed";
        use = [
          "extract"
          "reveal"
        ];
      }
      {
        mime = "application/x-rar";
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
          "open"
          "reveal"
        ];
      }
    ];
  };

  preview = {
    tab_size = 2;
    max_width = 600;
    max_height = 900;
    cache_dir = "";
    image_filter = "triangle";
    image_quality = 75;
    sixel_fraction = 15;
    ueberzug_scale = 1;
    ueberzug_offset = [
      0
      0
      0
      0
    ];
  };

  tasks = {
    micro_workers = 10;
    macro_workers = 25;
    bizarre_retry = 5;
    image_alloc = 536870912; # 512MB
    image_bound = [
      0
      0
    ];
    suppress_preload = false;
  };
}
