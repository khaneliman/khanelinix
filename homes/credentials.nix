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
  ];
}
