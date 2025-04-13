{
  help = {
    prepend_keymap = [
      {
        on = [ "q" ];
        run = "close";
        desc = "Exit the process";
      }

      # Navigation
      {
        on = [ "k" ];
        run = "arrow -1";
        desc = "Move cursor up";
      }
      {
        on = [ "j" ];
        run = "arrow 1";
        desc = "Move cursor down";
      }

      {
        on = [ "K" ];
        run = "arrow -5";
        desc = "Move cursor up 5 lines";
      }
      {
        on = [ "J" ];
        run = "arrow 5";
        desc = "Move cursor down 5 lines";
      }

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
        on = [ "<S-Up>" ];
        run = "arrow -5";
        desc = "Move cursor up 5 lines";
      }
      {
        on = [ "<S-Down>" ];
        run = "arrow 5";
        desc = "Move cursor down 5 lines";
      }

      # Filtering
      {
        on = [ "/" ];
        run = "filter";
        desc = "Apply a filter for the help items";
      }
    ];
  };
}
