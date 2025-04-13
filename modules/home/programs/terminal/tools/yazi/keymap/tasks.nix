{
  tasks = {
    prepend_keymap = [
      {
        on = [ "<Esc>" ];
        run = "close";
        desc = "Hide the task manager";
      }
      {
        on = [ "<C-q>" ];
        run = "close";
        desc = "Hide the task manager";
      }
      {
        on = [ "w" ];
        run = "close";
        desc = "Hide the task manager";
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
        on = [ "<Enter>" ];
        run = "inspect";
        desc = "Inspect the task";
      }
      {
        on = [ "x" ];
        run = "cancel";
        desc = "Cancel the task";
      }

      {
        on = [ "~" ];
        run = "help";
        desc = "Open help";
      }
    ];
  };
}
