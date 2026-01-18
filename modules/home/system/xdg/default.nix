{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.system.xdg;
in
{
  # NOTE: Can test with `, ashpd-demo`
  options.khanelinix.system.xdg = {
    enable = mkEnableOption "xdg";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gcr ];

    xdg = {
      enable = true;
      cacheHome = config.home.homeDirectory + "/.local/cache";

      configFile."xdg-desktop-portal-wlr/config" =
        lib.mkIf config.khanelinix.programs.graphical.wms.sway.enable
          {
            text = /* TOML */ ''
              [screencast]
              output_name=
              max_fps=30
              chooser_cmd=${lib.getExe pkgs.slurp} -f %o -or
              chooser_type=simple
            '';
          };

      mimeApps =
        let
          browser = [
            "firefox-devedition.desktop"
            "firefox.desktop"
          ];
          editor = [ "nvim.desktop" ];
          excel = [ "libreoffice-calc.desktop" ];
          fileManager = [ "nautilus.desktop" ];
          image = [ "feh.desktop" ];
          mail = [ "thunderbird.desktop" ];
          powerpoint = [ "libreoffice-impress.desktop" ];
          terminal = [
            "kitty.desktop"
            "foot.desktop"
            "wezterm.desktop"
            "alacritty.desktop"
          ];
          video = [ "vlc.desktop" ];
          word = [ "libreoffice-writer.desktop" ];

          # XDG MIME types
          associations = {
            "application/json" = editor;
            "application/pdf" = [ "org.pwmt.zathura.desktop" ];
            "application/rss+xml" = editor;
            "application/vnd.ms-excel" = excel;
            "application/vnd.ms-powerpoint" = powerpoint;
            "application/vnd.ms-word" = word;
            "application/vnd.oasis.opendocument.database" = [ "libreoffice-base.desktop" ];
            "application/vnd.oasis.opendocument.formula" = [ "libreoffice-math.desktop" ];
            "application/vnd.oasis.opendocument.graphics" = [ "libreoffice-draw.desktop" ];
            "application/vnd.oasis.opendocument.graphics-template" = [ "libreoffice-draw.desktop" ];
            "application/vnd.oasis.opendocument.presentation" = powerpoint;
            "application/vnd.oasis.opendocument.presentation-template" = powerpoint;
            "application/vnd.oasis.opendocument.spreadsheet" = excel;
            "application/vnd.oasis.opendocument.spreadsheet-template" = excel;
            "application/vnd.oasis.opendocument.text" = word;
            "application/vnd.oasis.opendocument.text-master" = word;
            "application/vnd.oasis.opendocument.text-template" = word;
            "application/vnd.oasis.opendocument.text-web" = word;
            "application/vnd.openxmlformats-officedocument.presentationml.presentation" = powerpoint;
            "application/vnd.openxmlformats-officedocument.presentationml.template" = powerpoint;
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = excel;
            "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = excel;
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = word;
            "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = word;
            "application/vnd.stardivision.calc" = excel;
            "application/vnd.stardivision.draw" = [ "libreoffice-draw.desktop" ];
            "application/vnd.stardivision.impress" = powerpoint;
            "application/vnd.stardivision.math" = [ "libreoffice-math.desktop" ];
            "application/vnd.stardivision.writer" = word;
            "application/vnd.sun.xml.base" = [ "libreoffice-base.desktop" ];
            "application/vnd.sun.xml.calc" = excel;
            "application/vnd.sun.xml.calc.template" = excel;
            "application/vnd.sun.xml.draw" = [ "libreoffice-draw.desktop" ];
            "application/vnd.sun.xml.draw.template" = [ "libreoffice-draw.desktop" ];
            "application/vnd.sun.xml.impress" = powerpoint;
            "application/vnd.sun.xml.impress.template" = powerpoint;
            "application/vnd.sun.xml.math" = [ "libreoffice-math.desktop" ];
            "application/vnd.sun.xml.writer" = word;
            "application/vnd.sun.xml.writer.global" = word;
            "application/vnd.sun.xml.writer.template" = word;
            "application/vnd.wordperfect" = word;
            "application/x-arj" = [ "org.kde.ark.desktop" ];
            "application/x-bittorrent" = [ "org.qbittorrent.qBittorrent.desktop" ];
            "application/x-bzip" = [ "org.kde.ark.desktop" ];
            "application/x-bzip-compressed-tar" = [ "org.kde.ark.desktop" ];
            "application/x-compress" = [ "org.kde.ark.desktop" ];
            "application/x-compressed-tar" = [ "org.kde.ark.desktop" ];
            "application/x-extension-htm" = browser;
            "application/x-extension-html" = browser;
            "application/x-extension-ics" = mail;
            "application/x-extension-m4a" = video;
            "application/x-extension-mp4" = video;
            "application/x-extension-shtml" = browser;
            "application/x-extension-xht" = browser;
            "application/x-extension-xhtml" = browser;
            "application/x-flac" = video;
            "application/x-gzip" = [ "org.kde.ark.desktop" ];
            "application/x-lha" = [ "org.kde.ark.desktop" ];
            "application/x-lhz" = [ "org.kde.ark.desktop" ];
            "application/x-lzop" = [ "org.kde.ark.desktop" ];
            "application/x-matroska" = video;
            "application/x-netshow-channel" = video;
            "application/x-quicktime-media-link" = video;
            "application/x-quicktimeplayer" = video;
            "application/x-rar" = [ "org.kde.ark.desktop" ];
            "application/x-shellscript" = editor;
            "application/x-smil" = video;
            "application/x-tar" = [ "org.kde.ark.desktop" ];
            "application/x-tarz" = [ "org.kde.ark.desktop" ];
            "application/x-wine-extension-ini" = [ "org.kde.kate.desktop" ];
            "application/x-zoo" = [ "org.kde.ark.desktop" ];
            "application/xhtml+xml" = browser;
            "application/xml" = editor;
            "application/zip" = [ "org.kde.ark.desktop" ];
            "audio/*" = video;
            "image/*" = image;
            "image/bmp" = [ "org.kde.gwenview.desktop" ];
            "image/gif" = [ "org.kde.gwenview.desktop" ];
            "image/jpeg" = [ "org.kde.gwenview.desktop" ];
            "image/jpg" = [ "org.kde.gwenview.desktop" ];
            "image/pjpeg" = [ "org.kde.gwenview.desktop" ];
            "image/png" = [ "org.kde.gwenview.desktop" ];
            "image/svg+xml" = [ "org.inkscape.Inkscape.desktop" ];
            "image/tiff" = [ "org.kde.gwenview.desktop" ];
            "image/x-compressed-xcf" = [ "gimp.desktop" ];
            "image/x-fits" = [ "gimp.desktop" ];
            "image/x-icb" = [ "org.kde.gwenview.desktop" ];
            "image/x-ico" = [ "org.kde.gwenview.desktop" ];
            "image/x-pcx" = [ "org.kde.gwenview.desktop" ];
            "image/x-portable-anymap" = [ "org.kde.gwenview.desktop" ];
            "image/x-portable-bitmap" = [ "org.kde.gwenview.desktop" ];
            "image/x-portable-graymap" = [ "org.kde.gwenview.desktop" ];
            "image/x-portable-pixmap" = [ "org.kde.gwenview.desktop" ];
            "image/x-psd" = [ "gimp.desktop" ];
            "image/x-xbitmap" = [ "org.kde.gwenview.desktop" ];
            "image/x-xcf" = [ "gimp.desktop" ];
            "image/x-xpixmap" = [ "org.kde.gwenview.desktop" ];
            "image/x-xwindowdump" = [ "org.kde.gwenview.desktop" ];
            "inode/directory" = fileManager;
            "message/rfc822" = mail;
            "text/*" = editor;
            "text/calendar" = mail;
            "text/html" = browser;
            "text/plain" = editor;
            "video/*" = video;
            "x-scheme-handler/about" = browser;
            "x-scheme-handler/chrome" = browser;
            "x-scheme-handler/discord" = [ "discord.desktop" ];
            "x-scheme-handler/etcher" = [ "balena-etcher-electron.desktop" ];
            "x-scheme-handler/ftp" = browser;
            "x-scheme-handler/gitkraken" = [ "GitKraken.desktop" ];
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;
            "x-scheme-handler/mailto" = mail;
            "x-scheme-handler/mid" = mail;
            "x-scheme-handler/terminal" = terminal;
            "x-scheme-handler/tg" = [ "org.telegram.desktop" ];
            "x-scheme-handler/unknown" = browser;
            "x-scheme-handler/webcal" = mail;
            "x-scheme-handler/webcals" = mail;
            "x-scheme-handler/x-github-client" = [ "github-desktop.desktop" ];
            "x-scheme-handler/x-github-desktop-auth" = [ "github-desktop.desktop" ];
            "x-www-browser" = browser;
            # "x-scheme-handler/chrome" = ["chromium-browser.desktop"];
          };
        in
        lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          enable = true;
          defaultApplications = associations;
          associations.added = associations;
        };

      portal = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        enable = true;
        xdgOpenUsePortal = true;

        config = {
          hyprland = mkIf config.khanelinix.programs.graphical.wms.hyprland.enable {
            default = [
              "hyprland"
              "gtk"
              "gnome"
            ];
            "org.freedesktop.impl.portal.Screencast" = "hyprland";
            "org.freedesktop.impl.portal.Screenshot" = "hyprland";
          };

          sway = mkIf config.khanelinix.programs.graphical.wms.sway.enable {
            default = lib.mkDefault [
              "wlr"
              "gtk"
              "gnome"
            ];

            "org.freedesktop.impl.portal.ScreenCast" = "wlr";
            "org.freedesktop.impl.portal.Screenshot" = "wlr";
          };

          common = {
            default = [
              "gtk"
              "gnome"
            ];

            # GTK
            "org.freedesktop.impl.portal.Access" = "gtk";
            "org.freedesktop.impl.portal.Account" = "gtk";
            "org.freedesktop.impl.portal.AppChooser" = "gtk";
            "org.freedesktop.impl.portal.Device" = "gtk";
            "org.freedesktop.impl.portal.DynamicLauncher" = "gtk";
            "org.freedesktop.impl.portal.Email" = "gtk";
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
            "org.freedesktop.impl.portal.Lockdown" = "gtk";
            "org.freedesktop.impl.portal.Notification" = "gtk";
            "org.freedesktop.impl.portal.Print" = "gtk";
            "org.freedesktop.impl.portal.Screencast" = "gtk";
            "org.freedesktop.impl.portal.Screenshot" = "gtk";

            # Gnome
            "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
            "org.freedesktop.impl.portal.Background" = "gnome";
            "org.freedesktop.impl.portal.Clipboard" = "gnome";
            "org.freedesktop.impl.portal.InputCapture" = "gnome";
            "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
          };
        };

        extraPortals =
          with pkgs;
          [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-gnome
            gnome-keyring
          ]
          ++ lib.optional config.wayland.windowManager.hyprland.enable xdg-desktop-portal-hyprland
          ++ lib.optional config.wayland.windowManager.sway.enable xdg-desktop-portal-wlr;
      };

      userDirs = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/screenshots";
        };
      };
    };
  };
}
