{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "precognition.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "tris203";
          repo = "precognition.nvim";
          rev = "v1.0.0";
          hash = "sha256-AqWYV/59ugKyOWALOCdycWVm0bZ7qb981xnuw/mAVzM=";
        };
      })
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>uP";
        action.__raw = ''
          function()
            if require("precognition").toggle() then
                vim.notify("precognition on")
            else
                vim.notify("precognition off")
            end
          end
        '';

        options = {
          desc = "Precognition Toggle";
          silent = true;
        };
      }
    ];
  };
}
