{
  config,
  lib,
  pkgs,
  ...
}:
let
  junit_jar = pkgs.fetchurl {
    url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.2/junit-platform-console-standalone-1.10.2.jar";
    hash = "sha256-od5VeCEpPOkDwhPGlBZf/1Ms+SCBusQji54Fs18E9D8=";
  };
in
{
  programs.nixvim = {

    plugins.neotest = {
      enable = true;

      settings = {
        adapters = lib.optionals config.programs.nixvim.plugins.rustaceanvim.enable [
          # lua
          ''require('rustaceanvim.neotest')''
        ];
      };

      adapters = {
        bash = {
          enable = true;
        };

        deno = {
          enable = true;
        };

        dotnet = {
          enable = true;
        };

        java = {
          enable = true;

          settings = {
            junit_jar = junit_jar.outPath;
          };
        };

        jest = {
          enable = true;
        };

        playwright = {
          enable = true;
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>uT";
        action = ":Neotest summary<CR>";
        options = {
          desc = "Toggle Neotest Summary";
          silent = true;
        };
      }
    ];
  };
}
