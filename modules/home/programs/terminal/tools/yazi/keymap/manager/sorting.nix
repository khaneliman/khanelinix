_: {
  keymap = [
    # Sorting
    {
      on = [
        ","
        "a"
      ];
      run = "sort alphabetical --reverse=no";
      desc = "Sort alphabetically";
    }
    {
      on = [
        ","
        "A"
      ];
      run = "sort alphabetical --reverse";
      desc = "Sort alphabetically (reverse)";
    }
    {
      on = [
        ","
        "c"
      ];
      run = "sort btime --reverse=no";
      desc = "Sort by creation time";
    }
    {
      on = [
        ","
        "C"
      ];
      run = "sort btime --reverse";
      desc = "Sort by creation time (reverse)";
    }
    {
      on = [
        ","
        "m"
      ];
      run = "sort mtime --reverse=no";
      desc = "Sort by modified time";
    }
    {
      on = [
        ","
        "M"
      ];
      run = "sort mtime --reverse";
      desc = "Sort by modified time (reverse)";
    }
    {
      on = [
        ","
        "n"
      ];
      run = "sort natural --reverse=no";
      desc = "Sort naturally";
    }
    {
      on = [
        ","
        "N"
      ];
      run = "sort natural --reverse";
      desc = "Sort naturally (reverse)";
    }
    {
      on = [
        ","
        "s"
      ];
      run = "sort size --reverse=no";
      desc = "Sort by size";
    }
    {
      on = [
        ","
        "S"
      ];
      run = "sort size --reverse";
      desc = "Sort by size (reverse)";
    }
  ];
}
