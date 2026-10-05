{ config, lib, ... }: {
  imports = [
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.terminal.tools.git.enable
          )
          {
            "github/access-token" = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/.config/gh/access-token";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.terminal.editors.neovim.enable
          )
          {
            wakatime = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/.wakatime.cfg";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          ((config.khanelinix.services.sops.enable or false) && config.khanelinix.suites.development.enable)
          {
            OPENAI_SECURA_KEY = {
              sopsFile = lib.getFile "secrets/CORE/default.yaml";
              path = "${config.home.homeDirectory}/.OPENAI_SECURA_KEY";
            };
            TAVILY_API_KEY = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/.TAVILY_API_KEY";
            };
            LUAROCKS_API_KEY = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/.LUAROCKS_API_KEY";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && (
              config.khanelinix.programs.terminal.tools.atuin.enable
              && config.khanelinix.programs.terminal.tools.atuin.sync.enable
            )
          )
          {
            "atuin/key" = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.terminal.tools.github-copilot-cli.enable
          )
          {
            "github/copilot-token" = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/.config/copilot/token";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.terminal.social.slack-term.enable
          )
          {
            slack-term = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/.config/slack-term/config";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.terminal.social.twitch-tui.enable
          )
          {
            twitch-tui = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/.config/twt/config.toml";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.graphical.editors.vscode.enable
          )
          {
            wakatime = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/.wakatime.cfg";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.graphical.bars.waybar.enable
          )
          {
            weather_config = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/weather_config.json";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.graphical.bars.ashell.enable
          )
          {
            weather_config = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/weather_config.json";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && config.khanelinix.programs.graphical.bars.sketchybar.enable
          )
          {
            weather_config = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
              path = "${config.home.homeDirectory}/weather_config.json";
            };
          };
    }
    {
      sops.secrets =
        lib.mkIf
          (
            (config.khanelinix.services.sops.enable or false)
            && (
              config.khanelinix.services.vdirsyncer.enable && config.khanelinix.services.vdirsyncer.google.enable
            )
          )
          {
            "calendar/google-client-id" = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
            };
            "calendar/google-client-secret" = {
              sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
            };
          };
    }
  ];
}
