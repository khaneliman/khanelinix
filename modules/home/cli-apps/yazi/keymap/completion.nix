_: {
  completion = {
    keymap = [
      {
        on = [ "<C-q>" ];
        run = "close";
        desc = "Cancel completion";
      }
      {
        on = [ "<Tab>" ];
        run = "close --submit";
        desc = "Submit the completion";
      }
      {
        on = [ "<Enter>" ];
        run = [
          "close --submit"
          "close_input --submit"
        ];
        desc = "Submit the completion and input";
      }

      {
        on = [ "<A-k>" ];
        run = "arrow -1";
        desc = "Move cursor up";
      }
      {
        on = [ "<A-j>" ];
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
        on = [ "~" ];
        run = "help";
        desc = "Open help";
      }
    ];
  };
}
