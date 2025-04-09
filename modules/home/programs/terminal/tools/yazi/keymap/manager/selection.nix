{
  keymap = [
    {
      on = [ "<Space>" ];
      run = [
        "toggle"
        "arrow 1"
      ];
      desc = "Toggle the current selection state";
    }
    {
      on = [ "v" ];
      run = "visual_mode";
      desc = "Enter visual mode (selection mode)";
    }
    {
      on = [ "V" ];
      run = "visual_mode --unset";
      desc = "Enter visual mode (unset mode)";
    }
    {
      on = [ "<C-a>" ];
      run = "toggle_all --state=on";
      desc = "Select all files";
    }
    {
      on = [ "<C-r>" ];
      run = "toggle_all";
      desc = "Inverse selection of all files";
    }
  ];
}
