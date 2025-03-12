{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkMerge
    optionalAttrs
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.programs.graphical.browsers.firefox;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.programs.graphical.browsers.firefox = with types; {
    enable = mkBoolOpt false "Whether or not to enable Firefox.";

    extraConfig = mkOpt str "" "Extra configuration for the user profile JS file.";
    gpuAcceleration = mkBoolOpt false "Enable GPU acceleration.";
    hardwareDecoding = mkBoolOpt false "Enable hardware video decoding.";

    policies = mkOpt attrs {
      CaptivePortal = false;
      DisableFirefoxStudies = true;
      DisableFormHistory = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisplayBookmarksToolbar = true;
      DontCheckDefaultBrowser = true;
      FirefoxHome = {
        Pocket = false;
        Snippets = false;
      };
      PasswordManagerEnabled = false;
      # PromptForDownloadLocation = true;
      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
      };
      ExtensionSettings = {
        "ebay@search.mozilla.org".installation_mode = "blocked";
        "amazondotcom@search.mozilla.org".installation_mode = "blocked";
        "bing@search.mozilla.org".installation_mode = "blocked";
        "ddg@search.mozilla.org".installation_mode = "blocked";
        "wikipedia@search.mozilla.org".installation_mode = "blocked";

        "frankerfacez@frankerfacez.com" = {
          installation_mode = "force_installed";
          install_url = "https://cdn.frankerfacez.com/script/frankerfacez-4.0-an+fx.xpi";
        };
      };
      Preferences = { };
    } "Policies to apply to firefox";

    settings = mkOpt attrs { } "Settings to apply to the profile.";
  };

  config = mkIf cfg.enable {
    home.file =
      let
        firefoxPath =
          if pkgs.stdenv.hostPlatform.isLinux then
            ".mozilla/firefox/${config.${namespace}.user.name}"
          else
            "/Users/${config.${namespace}.user.name}/Library/Application Support/Firefox/Profiles/${config.${namespace}.user.name}";
      in
      {
        "${firefoxPath}/chrome/img" = {
          source = lib.cleanSourceWith { src = lib.cleanSource ./chrome/img/.; };

          recursive = true;
        };
      };

    programs.firefox = {
      enable = true;
      package = if pkgs.stdenv.hostPlatform.isLinux then pkgs.firefox-devedition else null;

      inherit (cfg) policies;

      profiles = {
        "dev-edition-default" = {
          id = 0;
          path = "${config.${namespace}.user.name}";
        };

        ${config.${namespace}.user.name} = {
          inherit (cfg) extraConfig;
          inherit (config.${namespace}.user) name;

          id = 1;

          settings = mkMerge [
            cfg.settings
            {
              "accessibility.typeaheadfind.enablesound" = false;
              "accessibility.typeaheadfind.flashBar" = 0;
              "browser.aboutConfig.showWarning" = false;
              "browser.aboutwelcome.enabled" = false;
              "browser.bookmarks.autoExportHTML" = true;
              "browser.bookmarks.showMobileBookmarks" = true;
              "browser.meta_refresh_when_inactive.disabled" = true;
              "browser.newtabpage.activity-stream.default.sites" = "";
              "browser.newtabpage.activity-stream.showSponsored" = false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
              "browser.search.hiddenOneOffs" = "Google,Amazon.com,Bing,DuckDuckGo,eBay,Wikipedia (en)";
              "browser.search.suggest.enabled" = false;
              "browser.sessionstore.warnOnQuit" = true;
              "browser.shell.checkDefaultBrowser" = false;
              "browser.ssb.enabled" = true;
              "browser.startup.homepage.abouthome_cache.enabled" = true;
              "browser.startup.page" = 3;
              "browser.urlbar.keepPanelOpenDuringImeComposition" = true;
              "browser.urlbar.suggest.quicksuggest.sponsored" = false;
              "devtools.chrome.enabled" = true;
              "devtools.debugger.remote-enabled" = true;
              "dom.storage.next_gen" = true;
              "dom.forms.autocomplete.formautofill" = true;
              "extensions.htmlaboutaddons.recommendations.enabled" = false;
              "extensions.formautofill.addresses.enabled" = false;
              "extensions.formautofill.creditCards.enabled" = false;
              "general.autoScroll" = false;
              "general.smoothScroll.msdPhysics.enabled" = true;
              "geo.enabled" = false;
              "geo.provider.use_corelocation" = false;
              "geo.provider.use_geoclue" = false;
              "geo.provider.use_gpsd" = false;
              "gfx.font_rendering.directwrite.bold_simulation" = 2;
              "gfx.font_rendering.cleartype_params.enhanced_contrast" = 25;
              "gfx.font_rendering.cleartype_params.force_gdi_classic_for_families" = "";
              "intl.accept_languages" = "en-US,en";
              "media.eme.enabled" = true;
              "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "font.name.monospace.x-western" =
                if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Krypton" else "MonaspaceKrypton";
              "font.name.sans-serif.x-western" =
                if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Neon" else "MonaspaceNeon";
              "font.name.serif.x-western" =
                if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Neon" else "MonaspaceNeon";
              "signon.autofillForms" = false;
              "signon.firefoxRelay.feature" = "disabled";
              "signon.generation.enabled" = false;
              "signon.management.page.breach-alerts.enabled" = false;
              "xpinstall.signatures.required" = false;
            }
            (optionalAttrs cfg.gpuAcceleration {
              "dom.webgpu.enabled" = true;
              "gfx.webrender.all" = true;
              "layers.gpu-process.enabled" = true;
              "layers.mlgpu.enabled" = true;
            })
            (optionalAttrs cfg.hardwareDecoding {
              "media.ffmpeg.vaapi.enabled" = true;
              "media.gpu-process-decoder" = true;
              "media.hardware-video-decoding.enabled" = true;
            })
          ];

          # TODO: support alternative theme loading
          userChrome = ./chrome/userChrome.css;
        };
      };
    };
  };
}
