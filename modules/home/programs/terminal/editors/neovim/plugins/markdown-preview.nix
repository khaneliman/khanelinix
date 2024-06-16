{ config, lib, ... }:
{
  programs.nixvim = {
    plugins.markdown-preview = {
      enable = true;

      settings = {
        auto_close = false;
        theme = "dark";
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.markdown-preview.enable [
      {
        mode = "n";
        key = "<leader>pm";
        action = ":MarkdownPreview<cr>";
        options = {
          desc = "Markdown Preview";
          silent = true;
        };
      }
    ];
  };
}
