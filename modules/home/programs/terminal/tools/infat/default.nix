{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.infat;

  # Home Manager installs apps to this directory
  hmAppsPath = "Applications/Home Manager Apps";

  hasPkg = p: builtins.any (x: (x.pname or x.name) == p) config.home.packages;

  hasCaprine = config.khanelinix.programs.graphical.apps.caprine.enable or false;
  hasElement = hasPkg "element-desktop";
  hasFirefox = config.programs.firefox.enable or false;
  hasIina = hasPkg "iina";
  hasInkscape = hasPkg "inkscape" || hasPkg "inkscape-with-extensions";
  hasNeovide = hasPkg "neovide";
  hasPostman = hasPkg "postman";
  hasTeams = hasPkg "teams-for-linux";
  hasThunderbird = config.programs.thunderbird.enable or false;
  hasVSCode = config.khanelinix.programs.graphical.editors.vscode.enable or false;
  hasVesktop = config.khanelinix.programs.graphical.apps.vesktop.enable or false;

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
  videoPlayer = if hasIina then bundleIds.iina else "QuickTime Player";

  preferredTextEditors =
    (lib.optionals hasNeovide [ bundleIds.neovide ])
    ++ (lib.optionals hasVSCode [ bundleIds.vscode ])
    ++ [ "TextEdit" ];

  textEditor = builtins.head preferredTextEditors;
in
{
  options.khanelinix.programs.terminal.tools.infat = {
    enable = lib.mkEnableOption "infat";
  };

  config = mkIf cfg.enable {
    programs.infat = {
      # Infat documentation
      # See: https://github.com/khaneliman/infat
      enable = true;
      autoActivate = true;

      settings = {
        extensions = {
          # Document files
          md = textEditor;
          txt = textEditor;
          pdf = "Preview";

          # Code files
          nix = textEditor;
          rs = textEditor;
          py = textEditor;
          go = textEditor;
          js = textEditor;
          ts = textEditor;
          tsx = textEditor;
          jsx = textEditor;
          json = textEditor;
          yaml = textEditor;
          yml = textEditor;
          toml = textEditor;
          xml = textEditor;

          # Web files - Firefox Developer Edition
          html = mkIf hasFirefox bundleIds.firefox;
          htm = mkIf hasFirefox bundleIds.firefox;

          # Image files - Preview for viewing
          png = "Preview";
          jpg = "Preview";
          jpeg = "Preview";
          gif = "Preview";
          webp = "Preview";
          bmp = "Preview";
          svg = mkIf hasInkscape bundleIds.inkscape;

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
          web = mkIf hasFirefox bundleIds.firefox;
          http = mkIf hasFirefox bundleIds.firefox;
          https = mkIf hasFirefox bundleIds.firefox;
          feed = mkIf hasFirefox bundleIds.firefox;

          # Email - Thunderbird
          mailto = mkIf hasThunderbird bundleIds.thunderbird;

          # Communication apps
          discord = mkIf hasVesktop bundleIds.vesktop;
          element = mkIf hasElement bundleIds.element;
          # fb = bundleIds.caprine;
          messenger = mkIf hasCaprine bundleIds.caprine;
          msteams = mkIf hasTeams bundleIds.teams;

          # FaceTime and phone calls
          facetime = "FaceTime";
          tel = "FaceTime";

          # Development tools
          vscode = mkIf hasVSCode bundleIds.vscode;
          vscode-insiders = mkIf hasVSCode bundleIds.vscode;
          postman = mkIf hasPostman bundleIds.postman;
        };

        types = {
          # infat supertypes (not macOS UTIs)
          # Text and code
          plain-text = textEditor;
          text = textEditor;
          csv = textEditor;
          sourcecode = textEditor;
          c-source = textEditor;
          cpp-source = textEditor;
          objc-source = textEditor;
          shell = textEditor;
          makefile = textEditor;

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
