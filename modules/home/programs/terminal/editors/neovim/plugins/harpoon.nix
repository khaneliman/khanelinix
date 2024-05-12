_: {
  programs.nixvim = {
    plugins = {
      harpoon = {
        enable = true;

        keymapsSilent = true;

        keymaps = {
          addFile = "<leader>ha";
          toggleQuickMenu = "<leader>he";
          navFile = {
            "1" = "<leader>hj";
            "2" = "<leader>hk";
            "3" = "<leader>hl";
            "4" = "<leader>hm";
          };
        };
      };

      which-key.registrations."<leader>"."h" = {
        name = "󱡀 Harpoon";
        a = "Add";
        e = "QuickMenu";
        j = "1";
        k = "2";
        l = "3";
        m = "4";
      };
    };
  };
}
