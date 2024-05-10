_: {
  programs.nixvim = {
    plugins.which-key = {
      enable = true;
      # ignoreMissing = true;
      registrations = {
        "<leader>" = {
          "b" = {
            name = "󰓩 Buffers";
          };
          "d" = {
            name = "  Debug";
          };
          "g" = {
            name = "󰊢 Git";
          };
          "f" = {
            name = " Find";
          };
          "h" = {
            name = "󱡀 Harpoon";
            a = "Add";
            e = "QuickMenu";
            j = "1";
            k = "2";
            l = "3";
            m = "4";
          };
          "l" = {
            name = "  LSP";
            a = "Code Action";
            d = "Definition";
            D = "References";
            f = "Format";
            p = "Prev";
            n = "Next";
            t = "Type Definition";
            i = "Implementation";
            h = "Hover";
            r = "Rename";
          };
          "r" = {
            name = " Refactor";
          };
          "t" = {
            name = " Terminal";
          };
          "u" = {
            name = " UI/UX";
          };
        };
      };
    };
  };
}
