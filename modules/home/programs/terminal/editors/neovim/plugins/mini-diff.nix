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
        key = "<leader>ugo";
        action.__raw = # lua
          "MiniDiff.toggle_overlay";
        options = {
          desc = "Git Overlay toggle";
          silent = true;
        };
      }
    ];
  };
}
