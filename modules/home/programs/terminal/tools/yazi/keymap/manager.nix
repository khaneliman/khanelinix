_: {
  manager = {
    prepend_keymap = [
      {
        on = [ "l" ];
        run = "plugin --sync smart-enter";
        desc = "Enter the child directory, or open the file";
      }
      {
        on = [ "<Right>" ];
        run = "plugin --sync smart-enter";
        desc = "Enter the child directory, or open the file";
      }
      {
        on = [ "<C-v>" ];
        run = "shell 'dragon -x -i -T \"$1\"' --confirm";
        desc = "Drag and drop files";
      }
    ];

    keymap = [
      {
        on = [ "<Esc>" ];
        run = "escape";
        desc = "Exit visual mode, clear selected, or cancel search";
      }
      {
        on = [ "q" ];
        run = "close";
        desc = "Close the current tab; if it's the last tab, exit the process instead.";
      }
      {
        on = [ "Q" ];
        run = "quit --no-cwd-file";
        desc = "Exit the process without writing cwd-file";
      }
      {
        on = [ "<C-q>" ];
        run = "close";
        desc = "Close the current tab, or quit if it is last tab";
      }
      {
        on = [ "<C-z>" ];
        run = "suspend";
        desc = "Suspend the process";
      }

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
        run = "shell";
        desc = "Run a shell command";
      }
      {
        on = [ ":" ];
        run = "shell --block";
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
        run = "jump zoxide";
        desc = "Jump to a directory using zoxide";
      }
      {
        on = [ "Z" ];
        run = "jump fzf";
        desc = "Jump to a directory, or reveal a file using fzf";
      }

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

      # Tabs
      {
        on = [ "t" ];
        run = "tab_create --current";
        desc = "Create a new tab using the current path";
      }
      {
        on = [ "<C-n>" ];
        run = "tab_create --current";
        desc = "Create a new tab using the current path";
      }
      {
        on = [ "1" ];
        run = "tab_switch 0";
        desc = "Switch to the first tab";
      }
      {
        on = [ "2" ];
        run = "tab_switch 1";
        desc = "Switch to the second tab";
      }
      {
        on = [ "3" ];
        run = "tab_switch 2";
        desc = "Switch to the third tab";
      }
      {
        on = [ "4" ];
        run = "tab_switch 3";
        desc = "Switch to the fourth tab";
      }
      {
        on = [ "5" ];
        run = "tab_switch 4";
        desc = "Switch to the fifth tab";
      }
      {
        on = [ "6" ];
        run = "tab_switch 5";
        desc = "Switch to the sixth tab";
      }
      {
        on = [ "7" ];
        run = "tab_switch 6";
        desc = "Switch to the seventh tab";
      }
      {
        on = [ "8" ];
        run = "tab_switch 7";
        desc = "Switch to the eighth tab";
      }
      {
        on = [ "9" ];
        run = "tab_switch 8";
        desc = "Switch to the ninth tab";
      }

      {
        on = [ "[" ];
        run = "tab_switch -1 --relative";
        desc = "Switch to the previous tab";
      }
      {
        on = [ "]" ];
        run = "tab_switch 1 --relative";
        desc = "Switch to the next tab";
      }
      {
        on = [ "<S-Tab>" ];
        run = "tab_switch -1 --relative";
        desc = "Switch to the previous tab";
      }
      {
        on = [ "<Tab>" ];
        run = "tab_switch 1 --relative";
        desc = "Switch to the next tab";
      }

      {
        on = [ "{" ];
        run = "tab_swap -1";
        desc = "Swap the current tab with the previous tab";
      }
      {
        on = [ "}" ];
        run = "tab_swap 1";
        desc = "Swap the current tab with the next tab";
      }

      # Tasks
      {
        on = [ "w" ];
        run = "tasks_show";
        desc = "Show the tasks manager";
      }

      # Goto
      {
        on = [
          "g"
          "/"
        ];
        run = "cd /";
        desc = "Go to the root directory";
      }
      {
        on = [
          "g"
          "h"
        ];
        run = "cd ~";
        desc = "Go to the home directory";
      }
      {
        on = [
          "g"
          "c"
        ];
        run = "cd ~/.config";
        desc = "Go to the config directory";
      }
      {
        on = [
          "g"
          "t"
        ];
        run = "cd /tmp";
        desc = "Go to the temporary directory";
      }
      {
        on = [
          "g"
          "<Space>"
        ];
        run = "cd --interactive";
        desc = "Go to a directory interactively";
      }
      {
        on = [
          "g"
          "D"
        ];
        run = "cd ~/Downloads";
        desc = "Go to the downloads directory";
      }
      {
        on = [
          "g"
          "G"
        ];
        run = "cd ~/Documents/gitlab";
        desc = "Go to the GitLab directory";
      }
      {
        on = [
          "g"
          "M"
        ];
        run = "cd /mnt";
        desc = "Go to the /mnt directory";
      }
      {
        on = [
          "g"
          "c"
        ];
        run = "cd ~/.config";
        desc = "Go to the ~/.config directory";
      }
      {
        on = [
          "g"
          "d"
        ];
        run = "cd ~/Documents";
        desc = "Go to the Documents directory";
      }
      {
        on = [
          "g"
          "e"
        ];
        run = "cd /etc";
        desc = "Go to the /etc directory";
      }
      {
        on = [
          "g"
          "g"
        ];
        run = "cd ~/Documents/github";
        desc = "Go to the GitHub directory";
      }
      {
        on = [
          "g"
          "h"
        ];
        run = "cd ~";
        desc = "Go to the home directory";
      }
      {
        on = [
          "g"
          "i"
        ];
        # TODO: fix for yazi
        run = "shell cd('/run/media/' + os.getenv('USER'))";
        desc = "Run command to change to media directory";
      }
      {
        on = [
          "g"
          "l"
        ];
        run = "cd ~/.local/";
        desc = "Go to the ~/.local/ directory";
      }
      {
        on = [
          "g"
          "m"
        ];
        run = "cd /media";
        desc = "Go to the /media directory";
      }
      {
        on = [
          "g"
          "o"
        ];
        run = "cd /opt";
        desc = "Go to the /opt directory";
      }
      {
        on = [
          "g"
          "t"
        ];
        run = "cd /tmp";
        desc = "Go to the /tmp directory";
      }
      {
        on = [
          "g"
          "p"
        ];
        run = "cd ~/Pictures";
        desc = "Go to the Pictures directory";
      }
      {
        on = [
          "g"
          "s"
        ];
        run = "cd /srv";
        desc = "Go to the /srv directory";
      }
      {
        on = [
          "g"
          "u"
        ];
        run = "cd /usr";
        desc = "Go to the /usr directory";
      }
      {
        on = [
          "g"
          "v"
        ];
        run = "cd /var";
        desc = "Go to the /var directory";
      }
      {
        on = [
          "g"
          "w"
        ];
        run = "cd ~/.local/share/wallpapers";
        desc = "Go to the wallpapers directory";
      }

      # Help
      {
        on = [ "~" ];
        run = "help";
        desc = "Open help";
      }
    ];
  };
}
