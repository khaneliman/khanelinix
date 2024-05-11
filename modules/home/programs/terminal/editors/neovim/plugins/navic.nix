_: {
  programs.nixvim = {
    plugins.navic = {
      enable = true;
      lsp.autoAttach = true;
    };
  };
}
