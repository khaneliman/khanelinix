{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf mkMerge;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.apps.firefox;

  firefoxPath =
    if pkgs.stdenv.isLinux then ".mozilla/firefox/${config.khanelinix.user.name}"
    else "/Users/${config.khanelinix.user.name}/Library/Application Support/Firefox/Profiles/${config.khanelinix.user.name}";
in
{
  options.khanelinix.apps.firefox = with types;
    {
      enable = mkBoolOpt false "Whether or not to enable Firefox.";
      extraConfig =
        mkOpt str "" "Extra configuration for the user profile JS file.";
      settings = mkOpt attrs
        { } "Settings to apply to the profile.";
      userChrome =
        mkOpt str "" "Extra configuration for the user chrome CSS file.";
    };

  config = mkIf cfg.enable {
    home = {
      file = mkMerge [
        {
          "${firefoxPath}/native-messaging-hosts/com.dannyvankooten.browserpass.json".source = "${pkgs.browserpass}/lib/mozilla/native-messaging-hosts/com.dannyvankooten.browserpass.json";
          "${firefoxPath}/chrome/" = {
            source = lib.cleanSourceWith {
              src = lib.cleanSource ./chrome/.;
            };

            recursive = true;
          };
        }
      ];
    };

    programs.firefox = {
      enable = true;
      package = if pkgs.stdenv.isLinux then pkgs.firefox-beta else null;

      policies = {
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

          "magnolia_limited_permissions@12.34" = {
            installation_mode = "force_installed";
            install_url = "https://gitlab.com/magnolia1234/bpc-uploads/-/raw/master/bypass_paywalls_clean-3.4.4.0-custom.xpi";
          };
        };
        Preferences = { };
      };


      profiles.${config.khanelinix.user.name} = {
        inherit (cfg) extraConfig userChrome;
        inherit (config.khanelinix.user) name;

        id = 0;

        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          angular-devtools
          bitwarden
          darkreader
          firefox-color
          onepassword-password-manager
          reduxdevtools
          sponsorblock
          stylus
          tabcenter-reborn
          ublock-origin
          user-agent-string-switcher
        ];

        search = {
          default = "Google";
          privateDefault = "DuckDuckGo";
        };

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
            "dom.storage.next_gen" = true;
            "dom.webgpu.enabled" = true;
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
            "intl.accept_languages" = "en-US = en";
            "media.eme.enabled" = true;
            "media.ffmpeg.vaapi.enabled" = true;
            # "media.hardware-video-decoding.force-enabled" = true;
            "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "font.name.monospace.x-western" = "MonaspiceKr Nerd Font";
            "font.name.sans-serif.x-western" = "MonaspiceNe Nerd Font";
            "font.name.serif.x-western" = "MonaspiceNe Nerd Font";
            "signon.autofillForms" = false;
          }
        ];
      };
    };
  };
}
