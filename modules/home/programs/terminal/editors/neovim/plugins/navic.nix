_: {
  programs.nixvim = {
    # Shows the breadcrumb lsp node path in lualine
    plugins.navic = {
      enable = true;
      lsp.autoAttach = true;
    };
  };
}
