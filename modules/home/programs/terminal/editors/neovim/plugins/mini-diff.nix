{ lib, config, ... }:
{
  programs.nixvim = {
    plugins = {
      mini = {
        enable = true;

        modules = {
          diff = {
            view = {
              style = "sign";
            };
          };
        };
      };
    };

    keymaps = lib.mkIf (lib.hasAttr "diff" config.programs.nixvim.plugins.mini.modules) [
      {
        mode = "n";
        key = "<leader>ugo";
        action.__raw = # lua
          "MiniDiff.toggle_overlay";
        options = {
          desc = "Git Overlay toggle";
          silent = true;
        };
      }
    ];
  };
}
