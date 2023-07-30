{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.ranger;
in
{
  options.khanelinix.cli-apps.ranger = with types; {
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

    khanelinix.home = {
      configFile = with inputs; {
        "ranger/colorschemes/__init__.py".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/colorschemes/__init__.py";
        "ranger/colorschemes/catppuccin.py".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/colorschemes/catppuccin.py";
        "ranger/colorschemes/default.py".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/colorschemes/default.py";
        "ranger/config/console.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/config/console.conf";
        "ranger/config/interface.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/config/interface.conf";
        "ranger/config/navigation.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/config/navigation.conf";
        "ranger/config/operations.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/config/operations.conf";
        "ranger/config/options.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/config/options.conf";
        "ranger/config/pager.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/config/pager.conf";
        "ranger/config/taskview.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/config/taskview.conf";
        "ranger/config/visual.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/config/visual.conf";
        "ranger/config/local.conf".source = ./local.conf;
        "ranger/custom_commands".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/custom_commands";
        "ranger/plugins/__init__.py".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/plugins/__init__.py";
        "ranger/plugins/ranger_devicons".source = ranger-devicons;
        "ranger/plugins/ranger_udisk_menu".source = ranger-udisk-menu;
        "ranger/commands.py".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/commands.py";
        "ranger/rc.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/rc.conf";
        "ranger/rifle.conf".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/rifle.conf";
        "ranger/scope.sh".source = dotfiles.outPath + "/dots/shared/home/.config/ranger/scope.sh";
      };
    };
  };
}
