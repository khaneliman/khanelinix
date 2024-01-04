{ config
, lib
, options
, pkgs
, ...
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
      zoxide
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
          layout = [ 1 3 4 ];
          linemode = "size";
          show_hidden = true;
          show_symlink = true;
          sort_by = "alphabetical";
          sort_dir_first = true;
          sort_reverse = false;
          sort_sensitive = false;
        };
      };
    };

    xdg.configFile = {
      "yazi" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource ./configs/.;
        };

        recursive = true;
      };
    };
  };
}
