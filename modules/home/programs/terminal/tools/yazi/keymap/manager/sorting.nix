_: {
  keymap = [
    # Sorting
    {
      on = [
        ","
        "a"
      ];
      run = "sort alphabetical --dir_first";
      desc = "Sort alphabetically";
    }
    {
      on = [
        ","
        "A"
      ];
      run = "sort alphabetical --reverse --dir_first";
      desc = "Sort alphabetically (reverse)";
    }
    {
      on = [
        ","
        "c"
      ];
      run = "sort created --dir_first";
      desc = "Sort by creation time";
    }
    {
      on = [
        ","
        "C"
      ];
      run = "sort created --reverse --dir_first";
      desc = "Sort by creation time (reverse)";
    }
    {
      on = [
        ","
        "m"
      ];
      run = "sort modified --dir_first";
      desc = "Sort by modified time";
    }
    {
      on = [
        ","
        "M"
      ];
      run = "sort modified --reverse --dir_first";
      desc = "Sort by modified time (reverse)";
    }
    {
      on = [
        ","
        "n"
      ];
      run = "sort natural --dir_first";
      desc = "Sort naturally";
    }
    {
      on = [
        ","
        "N"
      ];
      run = "sort natural --reverse --dir_first";
      desc = "Sort naturally (reverse)";
    }
    {
      on = [
        ","
        "s"
      ];
      run = "sort size --dir_first";
      desc = "Sort by size";
    }
    {
      on = [
        ","
        "S"
      ];
      run = "sort size --reverse --dir_first";
      desc = "Sort by size (reverse)";
    }
  ];
}
