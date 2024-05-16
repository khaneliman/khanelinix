_: {

  keymap = [
    # Selection
    {
      on = [ "<Space>" ];
      run = [
        "select --state=none"
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
      run = "select_all --state=true";
      desc = "Select all files";
    }
    {
      on = [ "<C-r>" ];
      run = "select_all --state=none";
      desc = "Inverse selection of all files";
    }
  ];
}
