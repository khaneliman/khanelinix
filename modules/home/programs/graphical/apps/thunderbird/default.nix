{
  config,
  lib,
  pkgs,
  getPkgsUnstable,

  ...
}:
let
  inherit (lib)
    mkIf
    optionalString
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.apps.thunderbird;
  themeCfg = cfg.theme;
in
{
  options.khanelinix.programs.graphical.apps.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
    theme = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Thunderbird theme palette";
          isDark = mkOpt lib.types.bool true "Whether the Thunderbird theme uses dark chrome.";
          colors = {
            bg = mkOpt (lib.types.nullOr lib.types.str) null "Main Thunderbird background color.";
            surface = mkOpt (lib.types.nullOr lib.types.str) null "Toolbar and sidebar surface color.";
            surfaceAlt = mkOpt (lib.types.nullOr lib.types.str) null "Raised control surface color.";
            fg = mkOpt (lib.types.nullOr lib.types.str) null "Primary Thunderbird foreground color.";
            accent = mkOpt (lib.types.nullOr lib.types.str) null "Selection and active accent color.";
            accentSoft = mkOpt (lib.types.nullOr lib.types.str) null "Secondary accent color.";
            accentFg =
              mkOpt (lib.types.nullOr lib.types.str) null
                "Foreground color used on accent backgrounds.";
            border = mkOpt (lib.types.nullOr lib.types.str) null "Border and separator color.";
          };
        };
      };
      default = { };
      description = "Theme palette used to generate Thunderbird chrome CSS.";
    };
    accountsOrder = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Custom ordering of accounts.";
    };
    extraCalendarAccounts = lib.mkOption {
      type =
        let
          accountType = lib.types.submodule {
            options = {
              url = mkOpt lib.types.str null "Calendar url";
              type = mkOpt (lib.types.enum [
                "caldav"
                "http"
              ]) null "Calendar flavor";
              color = mkOpt lib.types.str null "color";
            };
          };
        in
        lib.types.attrsOf accountType;
      default = {
        "Milwaukee Bucks" = {
          url = "https://apidata.googleusercontent.com/caldav/v2/jeb1pn12iqgftnq21ae2qjljetlr43cv%40import.calendar.google.com/events/";
          type = "caldav";
          color = "#05491C";
        };
        "US Holidays" = {
          url = "https://apidata.googleusercontent.com/caldav/v2/cln2stbjc4hmgrrcd5i62ua0ctp6utbg5pr2sor1dhimsp31e8n6errfctm6abj3dtmg%40virtual/events/";
          type = "caldav";
          color = "#92cfe1";
        };
        "Green Bay Packers" = {
          url = "https://sports.yahoo.com/nfl/teams/gnb/ical.ics";
          type = "http";
          color = "#F9BC12";
        };
      };
      description = "Extra calendar accounts to configure.";
    };
    extraEmailAccounts = lib.mkOption {
      type =
        let
          accountType = lib.types.submodule {
            options = {
              enable = mkOpt lib.types.bool true "Enable this account";
              address = mkOpt lib.types.str null "Email address";
              flavor = mkOpt (lib.types.enum [
                "plain"
                "gmail.com"
                "runbox.com"
                "fastmail.com"
                "yandex.com"
                "outlook.office365.com"
                "davmail"
              ]) null "Email flavor";
            };
          };
        in
        lib.types.attrsOf accountType;
      default = { };
      description = "Extra email accounts to configure.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !themeCfg.enable || builtins.all (value: value != null) (builtins.attrValues themeCfg.colors);
        message = "Thunderbird theme colors must all be set when khanelinix.programs.graphical.apps.thunderbird.theme.enable is true.";
      }
    ];

    home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs;
      [
        birdtray
      ]
    );

    systemd.user.services.birdtray = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "Birdtray email notifier";
        After = [
          "graphical-session.target"
          "tray.target"
        ];
        Wants = [ "tray.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.birdtray}";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    accounts = {
      calendar.accounts =
        let
          mkCalendarConfig =
            {
              url,
              type,
              color ? "#9a9cff",
            }:
            {
              remote = {
                inherit type url;
                userName = config.khanelinix.user.email;
              };
              local = {
                inherit color;
              };
              thunderbird = {
                enable = true;
                profiles = [
                  config.khanelinix.user.name
                ];
                inherit color;
              };
            };
        in
        {
          "${config.khanelinix.user.email}" = {
            remote = {
              type = "caldav";
              url = "https://apidata.googleusercontent.com/caldav/v2/khaneliman12%40gmail.com/events/";
              userName = config.khanelinix.user.email;
            };
            primary = true;
            thunderbird = {
              enable = true;
              profiles = [
                config.khanelinix.user.name
              ];
              color = "#16a765";
            };
          };
        }
        // lib.mapAttrs (_name: mkCalendarConfig) cfg.extraCalendarAccounts;
      email.accounts =
        let
          mkEmailConfig =
            {
              address,
              primary ? false,
              enable ? true,
              flavor,
            }:
            let
              finalEnable =
                if flavor == "davmail" && !config.khanelinix.services.davmail.enable then
                  lib.warn "Davmail account '${address}' is disabled because davmail service is not enabled." false
                else
                  enable;
            in
            {
              enable = finalEnable;
              inherit
                address
                flavor
                primary
                ;
              realName = config.khanelinix.user.fullName;
              userName = lib.mkIf (flavor == "davmail") address;
              thunderbird = {
                enable = finalEnable;
                profiles = [
                  config.khanelinix.user.name
                ];
                settings = _id: {
                };
              };
            };
        in
        {
          "${config.khanelinix.user.email}" = mkEmailConfig {
            address = config.khanelinix.user.email;
            primary = true;
            flavor = "gmail.com";
          };
        }
        // lib.mapAttrs (_name: mkEmailConfig) cfg.extraEmailAccounts;
    };

    programs.thunderbird = {
      # Thunderbird documentation
      # See: https://support.mozilla.org/en-US/products/thunderbird
      enable = true;
      package =
        (getPkgsUnstable pkgs.stdenv.hostPlatform.system { inherit (pkgs) config; }).thunderbird-latest;

      profiles.${config.khanelinix.user.name} = {
        isDefault = true;

        inherit (cfg) accountsOrder;

        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "layers.acceleration.force-enabled" = true;
          "gfx.webrender.all" = true;
          "gfx.webrender.enabled" = true;
          "gfx.direct2d.disabled" = false;
          "svg.context-properties.content.enabled" = true;
          "browser.display.use_system_colors" = true;
          "browser.theme.dark-toolbar-theme" = themeCfg.isDark;
          "mailnews.default_sort_type" = 18;
          "mailnews.default_sort_order" = 2;
          "mail.tabs.drawInTitlebar" = false;
        };

        userChrome = optionalString themeCfg.enable /* css */ ''
          :root {
            color-scheme: ${if themeCfg.isDark then "dark" else "light"} !important;
            --khanelinix-thunderbird-bg: ${themeCfg.colors.bg};
            --khanelinix-thunderbird-surface: ${themeCfg.colors.surface};
            --khanelinix-thunderbird-surface-alt: ${themeCfg.colors.surfaceAlt};
            --khanelinix-thunderbird-fg: ${themeCfg.colors.fg};
            --khanelinix-thunderbird-accent: ${themeCfg.colors.accent};
            --khanelinix-thunderbird-accent-soft: ${themeCfg.colors.accentSoft};
            --khanelinix-thunderbird-accent-fg: ${themeCfg.colors.accentFg};
            --khanelinix-thunderbird-border: ${themeCfg.colors.border};

            --lwt-accent-color: var(--khanelinix-thunderbird-surface-alt) !important;
            --lwt-text-color: var(--khanelinix-thunderbird-fg) !important;
            --toolbar-bgcolor: var(--khanelinix-thunderbird-surface) !important;
            --toolbar-color: var(--khanelinix-thunderbird-fg) !important;
            --toolbar-field-background-color: var(--khanelinix-thunderbird-bg) !important;
            --toolbar-field-border-color: var(--khanelinix-thunderbird-border) !important;
            --toolbar-field-color: var(--khanelinix-thunderbird-fg) !important;
            --toolbar-field-focus-background-color: var(--khanelinix-thunderbird-bg) !important;
            --toolbar-field-focus-border-color: var(--khanelinix-thunderbird-accent) !important;
            --toolbar-field-focus-color: var(--khanelinix-thunderbird-fg) !important;
            --chrome-content-separator-color: var(--khanelinix-thunderbird-border) !important;
            --sidebar-background-color: var(--khanelinix-thunderbird-surface) !important;
            --sidebar-text-color: var(--khanelinix-thunderbird-fg) !important;
            --sidebar-border-color: var(--khanelinix-thunderbird-border) !important;
            --sidebar-highlight-background-color: var(--khanelinix-thunderbird-accent) !important;
            --sidebar-highlight-text-color: var(--khanelinix-thunderbird-accent-fg) !important;
            --lwt-selected-tab-background-color: var(--khanelinix-thunderbird-bg) !important;
            --tab-selected-bgcolor: var(--khanelinix-thunderbird-bg) !important;
            --tab-selected-textcolor: var(--khanelinix-thunderbird-fg) !important;
            --tab-line-color: var(--khanelinix-thunderbird-accent) !important;
            --tree-row-hover-background-color: var(--khanelinix-thunderbird-surface-alt) !important;
            --tree-selection-background: var(--khanelinix-thunderbird-accent-soft) !important;
            --tree-selection-color: var(--khanelinix-thunderbird-accent-fg) !important;
            background-color: var(--khanelinix-thunderbird-bg) !important;
            color: var(--khanelinix-thunderbird-fg) !important;
          }

          #messengerWindow,
          #tabmail,
          #mail3PaneTabBrowser,
          #messageBrowser,
          browser[type="content"],
          #folderPane,
          #threadPane,
          #calendarDisplayBox,
          #calendar-task-box,
          #taskBox,
          #today-pane-panel,
          #agenda-container,
          #agenda {
            background-color: var(--khanelinix-thunderbird-bg) !important;
            color: var(--khanelinix-thunderbird-fg) !important;
            border-color: var(--khanelinix-thunderbird-border) !important;
          }

          #spacesToolbar,
          #spacesToolbar > *,
          #folderPaneHeaderBar,
          #mail-toolbox,
          #navigation-toolbox,
          #tabs-toolbar,
          #titlebar,
          #calendar-toolbar2,
          #task-toolbar2,
          #event-toolbox,
          #today-pane-header,
          #agenda-toolbar,
          #mini-day-box {
            background-color: var(--khanelinix-thunderbird-surface) !important;
            color: var(--khanelinix-thunderbird-fg) !important;
            border-color: var(--khanelinix-thunderbird-border) !important;
          }

          #folderTree,
          #threadTree,
          tree,
          treechildren,
          richlistbox,
          html|table[is="tree-view-table"] {
            background-color: var(--khanelinix-thunderbird-bg) !important;
            color: var(--khanelinix-thunderbird-fg) !important;
            border-color: var(--khanelinix-thunderbird-border) !important;
          }

          treechildren::-moz-tree-row(selected),
          treechildren::-moz-tree-row(current, selected),
          richlistitem[selected="true"],
          .selected {
            background-color: var(--khanelinix-thunderbird-accent) !important;
            color: var(--khanelinix-thunderbird-accent-fg) !important;
          }

          treechildren::-moz-tree-cell-text(selected),
          treechildren::-moz-tree-cell-text(current, selected),
          richlistitem[selected="true"] *,
          .selected * {
            color: var(--khanelinix-thunderbird-accent-fg) !important;
          }

          button,
          input,
          select,
          textarea,
          search-textbox,
          .button-background {
            background-color: var(--khanelinix-thunderbird-surface-alt) !important;
            color: var(--khanelinix-thunderbird-fg) !important;
            border-color: var(--khanelinix-thunderbird-border) !important;
          }

          a,
          .text-link,
          .button-link {
            color: var(--khanelinix-thunderbird-accent-soft) !important;
          }

          splitter {
            border-color: var(--khanelinix-thunderbird-border) !important;
          }
        '';

        # TODO: Bundle extensions
      };
    };
  };
}
