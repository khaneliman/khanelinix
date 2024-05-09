{ config, lib, ... }:
{
  programs.nixvim = {
    plugins.project-nvim = {
      enable = true;
      enableTelescope = true;
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.telescope.enable [
      {
        mode = "n";
        key = "<leader>fp";
        action = ":Telescope projects<CR>";
        options = {
          desc = "Find projects";
          silent = true;
        };
      }
    ];
  };
}
