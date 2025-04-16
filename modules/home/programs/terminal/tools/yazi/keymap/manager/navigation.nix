{
  prepend_keymap = [
    {
      on = [ "K" ];
      run = "plugin arrow-parent -1";
      desc = "Move parent cursor up";
    }
    {
      on = [ "J" ];
      run = "plugin arrow-parent 1";
      desc = "Move parent cursor down";
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
      on = [
        "g"
        "T"
      ];
      run = "arrow top";
      desc = "Move cursor to the top";
    }
    {
      on = [ "G" ];
      run = "arrow bottom";
      desc = "Move cursor to the bottom";
    }
    {
      on = [ "<BackTab>" ];
      run = "tab_switch -1 --relative";
      desc = "Switch to the previous tab";
    }
    {
      on = [ "<Tab>" ];
      run = "tab_switch 1 --relative";
      desc = "Switch to the next tab";
    }
  ];
}
