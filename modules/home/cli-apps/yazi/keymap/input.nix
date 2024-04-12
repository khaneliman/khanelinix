_: {
  input = {
    keymap = [
      {
        on = [ "<C-q>" ];
        run = "close";
        desc = "Cancel input";
      }
      {
        on = [ "<Enter>" ];
        run = "close --submit";
        desc = "Submit the input";
      }
      {
        on = [ "<Esc>" ];
        run = "escape";
        desc = "Go back to normal mode, or cancel input";
      }

      # Mode
      {
        on = [ "i" ];
        run = "insert";
        desc = "Enter insert mode";
      }
      {
        on = [ "a" ];
        run = "insert --append";
        desc = "Enter append mode";
      }
      {
        on = [ "v" ];
        run = "visual";
        desc = "Enter visual mode";
      }
      {
        on = [ "V" ];
        run = [
          "move -999"
          "visual"
          "move 999"
        ];
        desc = "Enter visual mode and select all";
      }

      # Character-wise movement
      {
        on = [ "h" ];
        run = "move -1";
        desc = "Move cursor left";
      }
      {
        on = [ "l" ];
        run = "move 1";
        desc = "Move cursor right";
      }
      {
        on = [ "<Left>" ];
        run = "move -1";
        desc = "Move cursor left";
      }
      {
        on = [ "<Right>" ];
        run = "move 1";
        desc = "Move cursor right";
      }

      # Line-wise movement
      {
        on = [ "0" ];
        run = "move -999";
        desc = "Move to the BOL";
      }
      {
        on = [ "$" ];
        run = "move 999";
        desc = "Move to the EOL";
      }
      {
        on = [ "I" ];
        run = [
          "move -999"
          "insert"
        ];
        desc = "Move to the BOL, and enter insert mode";
      }
      {
        on = [ "A" ];
        run = [
          "move 999"
          "insert --append"
        ];
        desc = "Move to the EOL, and enter append mode";
      }

      # Word-wise movement
      {
        on = [ "b" ];
        run = "backward";
        desc = "Move to the beginning of the previous word";
      }
      {
        on = [ "w" ];
        run = "forward";
        desc = "Move to the beginning of the next word";
      }
      {
        on = [ "e" ];
        run = "forward --end-of-word";
        desc = "Move to the end of the next word";
      }

      # Delete
      {
        on = [ "<Backspace>" ];
        run = "backspace";
        desc = "Delete the character before the cursor";
      }
      {
        on = [ "<C-h>" ];
        run = "backspace";
        desc = "Delete the character before the cursor";
      }
      {
        on = [ "<C-d>" ];
        run = "backspace --under";
        desc = "Delete the character under the cursor";
      }

      # Deletion
      {
        on = [ "d" ];
        run = "delete --cut";
        desc = "Cut the selected characters";
      }
      {
        on = [ "D" ];
        run = [
          "delete --cut"
          "move 999"
        ];
        desc = "Cut until the EOL";
      }
      {
        on = [ "c" ];
        run = "delete --cut --insert";
        desc = "Cut the selected characters, and enter insert mode";
      }
      {
        on = [ "C" ];
        run = [
          "delete --cut --insert"
          "move 999"
        ];
        desc = "Cut until the EOL, and enter insert mode";
      }
      {
        on = [ "x" ];
        run = [
          "delete --cut"
          "move 1 --in-operating"
        ];
        desc = "Cut the current character";
      }

      # Kill
      {
        on = [ "<C-u>" ];
        run = "kill bol";
        desc = "Kill backwards to the BOL";
      }
      {
        on = [ "<C-k>" ];
        run = "kill eol";
        desc = "Kill forwards to the EOL";
      }
      {
        on = [ "<C-w>" ];
        run = "kill backward";
        desc = "Kill backwards to the start of the current word";
      }
      {
        on = [ "<A-d>" ];
        run = "kill forward";
        desc = "Kill forwards to the end of the current word";
      }

      # Cut/Yank/Paste
      {
        on = [ "d" ];
        run = "delete --cut";
        desc = "Cut the selected characters";
      }
      {
        on = [ "D" ];
        run = [
          "delete --cut"
          "move 999"
        ];
        desc = "Cut until the EOL";
      }
      {
        on = [ "c" ];
        run = "delete --cut --insert";
        desc = "Cut the selected characters and enter insert mode";
      }
      {
        on = [ "C" ];
        run = [
          "delete --cut --insert"
          "move 999"
        ];
        desc = "Cut until the EOL and enter insert mode";
      }
      {
        on = [ "x" ];
        run = [
          "delete --cut"
          "move 1 --in-operating"
        ];
        desc = "Cut the current character";
      }
      {
        on = [ "y" ];
        run = "yank";
        desc = "Copy the selected characters";
      }
      {
        on = [ "p" ];
        run = "paste";
        desc = "Paste the copied characters after the cursor";
      }
      {
        on = [ "P" ];
        run = "paste --before";
        desc = "Paste the copied characters before the cursor";
      }

      # Undo/Redo
      {
        on = [ "u" ];
        run = "undo";
        desc = "Undo the last operation";
      }
      {
        on = [ "<C-r>" ];
        run = "redo";
        desc = "Redo the last operation";
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
