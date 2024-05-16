{ config, ... }:
let
  copy = import ./manager/copy.nix { };
  find = import ./manager/find.nix { };
  goto = import ./manager/goto.nix { inherit config; };
  navigation = import ./manager/navigation.nix { };
  operation = import ./manager/operation.nix { };
  selection = import ./manager/selection.nix { };
  sorting = import ./manager/sorting.nix { };
  tabs = import ./manager/tabs.nix { inherit config; };
in
{
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

    keymap =
      copy.keymap
      ++ find.keymap
      ++ goto.keymap
      ++ navigation.keymap
      ++ operation.keymap
      ++ selection.keymap
      ++ sorting.keymap
      ++ tabs.keymap
      ++ [
        # Exit
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

        # Tasks
        {
          on = [ "w" ];
          run = "tasks_show";
          desc = "Show the tasks manager";
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
