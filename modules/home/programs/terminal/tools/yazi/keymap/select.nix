{
  select = {
    prepend_keymap = [
      {
        on = [ "<C-q>" ];
        run = "close";
        desc = "Cancel selection";
      }
      {
        on = [ "<Esc>" ];
        run = "close";
        desc = "Cancel selection";
      }
      {
        on = [ "<Enter>" ];
        run = "close --submit";
        desc = "Submit the selection";
      }

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
        on = [ "~" ];
        run = "help";
        desc = "Open help";
      }
    ];
  };
}
