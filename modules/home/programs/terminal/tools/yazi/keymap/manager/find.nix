_: {
  keymap = [
    # Find
    {
      on = [ "/" ];
      run = "find --smart";
    }
    {
      on = [ "?" ];
      run = "find --previous --smart";
    }
    {
      on = [ "n" ];
      run = "find_arrow";
    }
    {
      on = [ "N" ];
      run = "find_arrow --previous";
    }
  ];
}
