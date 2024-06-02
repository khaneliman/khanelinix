_: {
  programs.nixvim = {
    plugins = {
      mini = {
        enable = true;

        modules = {
          diff = {
            view = {
              style = "sign";
            };
          };
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>gto";
        action.__raw = # lua
          "MiniDiff.toggle_overlay";
        options = {
          desc = "Toggle Git Overlay";
          silent = true;
        };
      }
    ];
  };
}
