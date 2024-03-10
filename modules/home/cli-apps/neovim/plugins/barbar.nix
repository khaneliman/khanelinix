_: {
  programs.nixvim.plugins.barbar = {
    enable = true;

    insertAtEnd = true;

    keymaps = {
      silent = true;

      next = "<TAB>";
      previous = "<S-TAB>";
      close = "<C-w>";
      pin = "<C-p>";
    };
  };
}
