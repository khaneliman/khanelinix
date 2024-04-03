{ config, lib, pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      (pkgs.vimUtils.buildVimPlugin {
        name = "nvim-nio";
        src = pkgs.fetchFromGitHub {
          owner = "nvim-neotest";
          repo = "nvim-nio";
          rev = "v1.8.1";
          hash = "sha256-MHCrUisx3blgHWFyA5IHcSwKvC1tK1Pgy/jADBkoXX0=";
        };
      })
    ];

    plugins.neotest = {
      enable = true;

      settings = {
        adapters = lib.optionals config.programs.nixvim.plugins.rustaceanvim.enable [
          /*lua*/
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
        };

        jest = {
          enable = true;
        };

        playwright = {
          enable = true;
        };
      };
    };

    keymaps = [{
      mode = "n";
      key = "<leader>un";
      action = ":Neotest summary<CR>";
      options = {
        desc = "Toggle Neotest Summary";
        silent = true;
      };
    }];
  };
}
