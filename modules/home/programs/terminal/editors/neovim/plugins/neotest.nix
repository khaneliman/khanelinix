{ config, lib, ... }:
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
            # NOTE: just run NeotestJava setup
            # Not sure why this wasn't working
            # junit_jar =
            #   pkgs.fetchurl
            #     {
            #       url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.1/junit-platform-console-standalone-1.10.1.jar";
            #       hash = "sha256-tC6qU9E1dtF9tfuLKAcipq6eNtr5X0JivG6W1Msgcl8=";
            #     }
            #     .outPath;
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
