_: {
  keymap = [
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
      on = [ "<C-u>" ];
      run = "arrow -50%";
      desc = "Move cursor up half page";
    }
    {
      on = [ "<C-d>" ];
      run = "arrow 50%";
      desc = "Move cursor down half page";
    }
    {
      on = [ "<PageUp>" ];
      run = "arrow -100%";
      desc = "Move cursor up one page";
    }
    {
      on = [ "<PageDown>" ];
      run = "arrow 100%";
      desc = "Move cursor down one page";
    }
    {
      on = [ "h" ];
      run = "leave";
      desc = "Go back to the parent directory";
    }
    {
      on = [ "l" ];
      run = "enter";
      desc = "Enter the child directory";
    }
    {
      on = [ "H" ];
      run = "back";
      desc = "Go back to the previous directory";
    }
    {
      on = [ "L" ];
      run = "forward";
      desc = "Go forward to the next directory";
    }
    {
      on = [ "<C-k>" ];
      run = "peek -5";
      desc = "Peek up 5 units in the preview";
    }
    {
      on = [ "<C-j>" ];
      run = "peek 5";
      desc = "Peek down 5 units in the preview";
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
      on = [ "<Left>" ];
      run = "leave";
      desc = "Go back to the parent directory";
    }
    {
      on = [ "<Right>" ];
      run = "enter";
      desc = "Enter the child directory";
    }
    {
      on = [
        "g"
        "T"
      ];
      run = "arrow -99999999";
      desc = "Move cursor to the top";
    }
    {
      on = [ "G" ];
      run = "arrow 99999999";
      desc = "Move cursor to the bottom";
    }
  ];
}
