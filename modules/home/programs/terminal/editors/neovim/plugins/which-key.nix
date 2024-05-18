_: {
  programs.nixvim = {
    plugins.which-key = {
      enable = true;

      keyLabels = {
        "<space>" = "SPACE";
        "<leader>" = "SPACE";
        "<cr>" = "RETURN";
        "<CR>" = "RETURN";
        "<tab>" = "TAB";
        "<TAB>" = "TAB";
        "<bs>" = "BACKSPACE";
        "<BS>" = "BACKSPACE";
      };

      registrations = {
        "<leader>" = {
          "b" = {
            name = "󰓩 Buffers";
            s = "󰒺 Sort";
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

      window = {
        border = "single";
      };
    };
  };
}
