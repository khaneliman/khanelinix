_: {
  keymap = [
    # Operation
    {
      on = [ "o" ];
      run = "open";
      desc = "Open the selected files";
    }
    {
      on = [ "O" ];
      run = "open --interactive";
      desc = "Open the selected files interactively";
    }
    {
      on = [ "<Enter>" ];
      run = "open";
      desc = "Open the selected files";
    }
    {
      on = [ "<C-Enter>" ];
      run = "open --interactive";
      desc = "Open the selected files interactively";
    }
    {
      on = [ "y" ];
      run = "yank";
      desc = "Copy the selected files";
    }
    {
      on = [ "x" ];
      run = "yank --cut";
      desc = "Cut the selected files";
    }
    {
      on = [ "p" ];
      run = "paste";
      desc = "Paste the files";
    }
    {
      on = [ "P" ];
      run = "paste --force";
      desc = "Paste the files (overwrite if the destination exists)";
    }
    {
      on = [ "-" ];
      run = "link";
      desc = "Symlink the absolute path of files";
    }
    {
      on = [ "_" ];
      run = "link --relative";
      desc = "Symlink the relative path of files";
    }
    {
      on = [ "d" ];
      run = "remove";
      desc = "Move the files to the trash";
    }
    {
      on = [ "D" ];
      run = "remove --permanently";
      desc = "Permanently delete the files";
    }
    {
      on = [ "a" ];
      run = "create";
      desc = "Create a file or directory (ends with / for directories)";
    }
    {
      on = [ "r" ];
      run = "rename";
      desc = "Rename a file or directory";
    }
    {
      on = [ "," ];
      run = "shell --interactive";
      desc = "Run a shell command";
    }
    {
      on = [ ":" ];
      run = "shell --block --interactive";
      desc = "Run a shell command (block the UI until the command finishes)";
    }
    {
      on = [ "." ];
      run = "hidden toggle";
      desc = "Toggle the visibility of hidden files";
    }
    {
      on = [ "s" ];
      run = "search fd";
      desc = "Search files by name using fd";
    }
    {
      on = [ "S" ];
      run = "search rg";
      desc = "Search files by content using ripgrep";
    }
    {
      on = [ "<C-s>" ];
      run = "search none";
      desc = "Cancel the ongoing search";
    }
    {
      on = [ "z" ];
      run = "plugin zoxide";
      desc = "Jump to a directory using zoxide";
    }
    {
      on = [ "Z" ];
      run = "plugin fzf";
      desc = "Jump to a directory, or reveal a file using fzf";
    }
  ];
}
