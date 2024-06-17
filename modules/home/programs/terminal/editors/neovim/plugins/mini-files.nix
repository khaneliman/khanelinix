{ config, lib, ... }:
{
  programs.nixvim = {
    keymaps = lib.mkIf (lib.hasAttr "files" config.programs.nixvim.plugins.mini.modules) [
      {
        mode = "n";
        key = "<leader>E";
        action = ":lua MiniFiles.open()<CR>";
        options = {
          desc = "Mini Files";
          silent = true;
        };
      }
    ];

    plugins = {
      mini = {
        enable = true;

        modules = {
          # files = { };
        };
      };
    };
  };
}
