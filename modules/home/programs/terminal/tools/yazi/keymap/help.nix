{
  help = {
    prepend_keymap = [
      {
        on = [ "<Up>" ];
        run = "arrow -1";
        desc = "Move cursor up";
      }
      {
        on = [ "<Down>" ];
        run = "arrow 1";
        desc = "Move cursor down";
      }
      {
        on = [ "<C-p>" ];
        run = "arrow -1";
        desc = "Move cursor up";
      }
      {
        on = [ "<C-n>" ];
        run = "arrow 1";
        desc = "Move cursor down";
      }
      {
        on = [ "<S-Up>" ];
        run = "arrow -5";
        desc = "Move cursor up 5 lines";
      }
      {
        on = [ "<S-Down>" ];
        run = "arrow 5";
        desc = "Move cursor down 5 lines";
      }
    ];
  };
}
