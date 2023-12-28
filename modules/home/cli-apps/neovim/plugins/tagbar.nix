{ ... }: {
  programs.nixvim = {
    plugins.tagbar = {
      enable = true;
      extraConfig.width = 50;
    };

    keymaps = [
      {
        mode = "n";
        key = "<C-g>";
        action = ":TagbarToggle<cr>";
        options.silent = true;
      }
    ];
  };
}
