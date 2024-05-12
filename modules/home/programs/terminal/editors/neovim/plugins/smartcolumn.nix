{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ smartcolumn-nvim ];

    extraConfigLuaPre = # lua
      ''
        require("smartcolumn").setup({
          colorcolumn = "80",

          disabled_filetypes = {
            "help",
            "text",
            "markdown",
            "neo-tree",
            "checkhealth",
            "lspinfo",
            "noice",
          },

          custom_colorcolumn = {
            go = {"100", "130"},
            java = { "100", "140" },
            nix = { "100", "120" },
            rust = { "80", "100" },
          },

          scope = "file",
        })
      '';
  };
}
