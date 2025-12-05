{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf elem;

  cfg = config.khanelinix.programs.terminal.tools.infat;

  # Home Manager installs apps to this directory
  hmAppsPath = "Applications/Home Manager Apps";

  videoPlayer =
    if elem pkgs.iina config.home.packages then "${hmAppsPath}/IINA.app" else "QuickTime Player";
in
{
  options.khanelinix.programs.terminal.tools.infat = {
    enable = lib.mkEnableOption "infat";
  };

  config = mkIf cfg.enable {
    programs.infat = {
      enable = true;
      autoActivate = true;

      settings = {
        extensions = {
          # Document files - Neovide (GUI Neovim wrapper)
          md = "${hmAppsPath}/Neovide.app";
          txt = "${hmAppsPath}/Neovide.app";
          pdf = "Preview";

          # Code files - Neovide (GUI Neovim)
          nix = "${hmAppsPath}/Neovide.app";
          rs = "${hmAppsPath}/Neovide.app";
          py = "${hmAppsPath}/Neovide.app";
          go = "${hmAppsPath}/Neovide.app";
          js = "${hmAppsPath}/Neovide.app";
          ts = "${hmAppsPath}/Neovide.app";
          tsx = "${hmAppsPath}/Neovide.app";
          jsx = "${hmAppsPath}/Neovide.app";
          json = "${hmAppsPath}/Neovide.app";
          yaml = "${hmAppsPath}/Neovide.app";
          yml = "${hmAppsPath}/Neovide.app";
          toml = "${hmAppsPath}/Neovide.app";
          xml = "${hmAppsPath}/Neovide.app";

          # Web files - Firefox Developer Edition
          html = "${hmAppsPath}/Firefox Developer Edition.app";
          htm = "${hmAppsPath}/Firefox Developer Edition.app";

          # Image files - Preview for viewing
          png = "Preview";
          jpg = "Preview";
          jpeg = "Preview";
          gif = "Preview";
          webp = "Preview";
          bmp = "Preview";
          svg = "Inkscape";

          # Video files - IINA if installed, otherwise QuickTime Player
          mp4 = videoPlayer;
          mkv = videoPlayer;
          mov = videoPlayer;
          avi = videoPlayer;
          webm = videoPlayer;
          flv = videoPlayer;

          # Audio files - Music (macOS default)
          mp3 = "Music";
          flac = "Music";
          wav = "Music";
          ogg = "Music";
          m4a = "Music";
          aac = "Music";
        };

        schemes = {
          # Web protocols - Firefox Developer Edition
          web = "${hmAppsPath}/Firefox Developer Edition.app";
          http = "${hmAppsPath}/Firefox Developer Edition.app";
          https = "${hmAppsPath}/Firefox Developer Edition.app";
          feed = "${hmAppsPath}/Firefox Developer Edition.app";

          # Email - Thunderbird
          mailto = "${hmAppsPath}/Thunderbird.app";

          # Communication apps
          discord = "${hmAppsPath}/Vesktop.app";
          element = "${hmAppsPath}/Element.app";
          # fb = "${hmAppsPath}/Caprine.app";
          messenger = "${hmAppsPath}/Caprine.app";
          msteams = "${hmAppsPath}/teams-for-linux.app";

          # FaceTime and phone calls
          facetime = "FaceTime";
          tel = "FaceTime";

          # Development tools
          vscode = "${hmAppsPath}/Visual Studio Code.app";
          vscode-insiders = "${hmAppsPath}/Visual Studio Code.app";
          postman = "${hmAppsPath}/Postman.app";
        };

        types = {
          # infat supertypes (not macOS UTIs)
          # Text and code
          plain-text = "${hmAppsPath}/Neovide.app";
          text = "${hmAppsPath}/Neovide.app";
          csv = "${hmAppsPath}/Neovide.app";
          sourcecode = "${hmAppsPath}/Neovide.app";
          c-source = "${hmAppsPath}/Neovide.app";
          cpp-source = "${hmAppsPath}/Neovide.app";
          objc-source = "${hmAppsPath}/Neovide.app";
          shell = "${hmAppsPath}/Neovide.app";
          makefile = "${hmAppsPath}/Neovide.app";

          # Images
          image = "Preview";
          raw-image = "Preview";

          # Video
          video = videoPlayer;
          movie = videoPlayer;
          mp4-movie = videoPlayer;

          # Audio
          audio = "Music";
          mp4-audio = "Music";

          # Archives - use macOS Archive Utility
          archive = "Archive Utility";

          # File system
          directory = "/System/Library/CoreServices/Finder.app";
          folder = "/System/Library/CoreServices/Finder.app";
        };
      };
    };
  };
}
