{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.infat;

  # Home Manager installs apps to this directory
  hmAppsPath = "Applications/Home Manager Apps";

  hasPkg = p: builtins.any (x: (x.pname or x.name) == p) config.home.packages;

  # Bundle IDs for nixpkgs-installed macOS apps
  # These are stable identifiers that don't change across nixpkgs versions / installation locations
  bundleIds = {
    neovide = "com.neovide.neovide";
    firefox = config.programs.firefox.darwinDefaultsId or "org.nixos.firefoxdeveloperedition";
    thunderbird = "org.nixos.thunderbird";
    vesktop = "dev.vencord.vesktop";
    # element = "org.nixos.Element";
    element = "im.riot.app";
    caprine = "com.sindresorhus.caprine";
    # teams-for-linux has non-standard bundle ID, use full path instead
    teams = "${config.home.homeDirectory}/${hmAppsPath}/teams-for-linux.app";
    vscode = "com.microsoft.VSCode";
    postman = "com.postmanlabs.mac";
    iina = "com.colliderli.iina";
    inkscape = "org.nixos.Inkscape";
  };

  # Use IINA if installed, otherwise fall back to QuickTime Player
  videoPlayer =
    if lib.elem pkgs.iina config.home.packages then bundleIds.iina else "QuickTime Player";
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
          md = bundleIds.neovide;
          txt = bundleIds.neovide;
          pdf = "Preview";

          # Code files - Neovide (GUI Neovim)
          nix = bundleIds.neovide;
          rs = bundleIds.neovide;
          py = bundleIds.neovide;
          go = bundleIds.neovide;
          js = bundleIds.neovide;
          ts = bundleIds.neovide;
          tsx = bundleIds.neovide;
          jsx = bundleIds.neovide;
          json = bundleIds.neovide;
          yaml = bundleIds.neovide;
          yml = bundleIds.neovide;
          toml = bundleIds.neovide;
          xml = bundleIds.neovide;

          # Web files - Firefox Developer Edition
          html = mkIf config.programs.firefox.enable bundleIds.firefox;
          htm = mkIf config.programs.firefox.enable bundleIds.firefox;

          # Image files - Preview for viewing
          png = "Preview";
          jpg = "Preview";
          jpeg = "Preview";
          gif = "Preview";
          webp = "Preview";
          bmp = "Preview";
          svg = mkIf (hasPkg "inkscape") bundleIds.inkscape;

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
          web = mkIf config.programs.firefox.enable bundleIds.firefox;
          http = mkIf config.programs.firefox.enable bundleIds.firefox;
          https = mkIf config.programs.firefox.enable bundleIds.firefox;
          feed = mkIf config.programs.firefox.enable bundleIds.firefox;

          # Email - Thunderbird
          mailto = mkIf config.programs.thunderbird.enable bundleIds.thunderbird;

          # Communication apps
          discord = mkIf config.khanelinix.programs.graphical.apps.vesktop.enable bundleIds.vesktop;
          element = mkIf (hasPkg "element-desktop") bundleIds.element;
          # fb = bundleIds.caprine;
          messenger = mkIf config.khanelinix.programs.graphical.apps.caprine.enable bundleIds.caprine;
          msteams = mkIf (hasPkg "teams-for-linux") bundleIds.teams;

          # FaceTime and phone calls
          facetime = "FaceTime";
          tel = "FaceTime";

          # Development tools
          vscode = mkIf config.khanelinix.programs.graphical.editors.vscode.enable bundleIds.vscode;
          vscode-insiders = mkIf config.khanelinix.programs.graphical.editors.vscode.enable bundleIds.vscode;
          postman = mkIf (hasPkg "postman") bundleIds.postman;
        };

        types = {
          # infat supertypes (not macOS UTIs)
          # Text and code
          plain-text = bundleIds.neovide;
          text = bundleIds.neovide;
          csv = bundleIds.neovide;
          sourcecode = bundleIds.neovide;
          c-source = bundleIds.neovide;
          cpp-source = bundleIds.neovide;
          objc-source = bundleIds.neovide;
          shell = bundleIds.neovide;
          makefile = bundleIds.neovide;

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
