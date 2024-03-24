{ config, lib, ... }:
let inherit (lib) mkIf; in
{
  programs.nixvim = {
    plugins.noice = {
      enable = true;

      messages = {
        view = "mini";
        viewError = "mini";
        viewWarn = "mini";
      };

      lsp.override = {
        "vim.lsp.util.convert_input_to_markdown_lines" = true;
        "vim.lsp.util.stylize_markdown" = true;
        "cmp.entry.get_documentation" = true;
      };
      presets = {
        bottom_search = true;
        command_palette = true;
        long_message_to_split = true;
        inc_rename = true;
        lsp_doc_border = false;
      };
    };

    keymaps = mkIf config.programs.nixvim.plugins.telescope.enable [
      {
        mode = "n";
        key = "<leader>fn";
        action = ":Telescope noice<CR>";
        options = {
          desc = "Find notifications";
          silent = true;
        };
      }
    ];
  };
}
