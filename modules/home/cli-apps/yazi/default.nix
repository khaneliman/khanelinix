{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.yazi;
in
{
  options.khanelinix.cli-apps.yazi = {
    enable = mkBoolOpt false "Whether or not to enable yazi.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ripgrep
      zoxide
      xdragon
    ];

    programs.yazi = {
      enable = true;
      package = pkgs.yazi;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;

      settings = {
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
          archive = [
            {
              desc = "Open archive files with atool";
              run = "${lib.getExe pkgs.atool} --extract --each --subdir --quiet -- \"$@\"";
              block = true;
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
              use = "archive";
            }
            {
              name = "*.zip";
              use = "archive";
            }
            {
              name = "*.gz";
              use = "archive";
            }
            {
              name = "*.xz";
              use = "archive";
            }
            {
              name = "*.tar";
              use = "archive";
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
      };
    };

    xdg.configFile = {
      "yazi" = {
        source = lib.cleanSourceWith { src = lib.cleanSource ./configs/.; };

        recursive = true;
      };
    };
  };
}
