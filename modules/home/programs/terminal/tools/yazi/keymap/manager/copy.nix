_: {
  keymap = [
    # Copy
    {
      on = [
        "c"
        "c"
      ];
      run = "copy path";
      desc = "Copy the absolute path";
    }
    {
      on = [
        "c"
        "d"
      ];
      run = "copy dirname";
      desc = "Copy the path of the parent directory";
    }
    {
      on = [
        "c"
        "f"
      ];
      run = "copy filename";
      desc = "Copy the name of the file";
    }
    {
      on = [
        "c"
        "n"
      ];
      run = "copy name_without_ext";
      desc = "Copy the name of the file without the extension";
    }
  ];
}
