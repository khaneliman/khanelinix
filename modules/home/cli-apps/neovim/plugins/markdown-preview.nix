_: {
  programs.nixvim = {
    plugins.markdown-preview = {
      enable = true;

      settings = {
        auto_close = false;
        theme = "dark";
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>m";
        action = ":MarkdownPreview<cr>";
        options.silent = true;
      }
    ];
  };
}
