_: {
  programs.nixvim = {
    plugins = {
      nvim-lightbulb = {
        enable = true;

        settings = {
          autocmd = {
            enabled = true;
            updatetime = 200;
          };
          line = {
            enabled = true;
          };
          number = {
            enabled = true;
          };
          sign = {
            enabled = true;
            text = "󰌶";
          };
          status_text = {
            enabled = true;
            text = " 󰌶 ";
          };
        };
      };
    };
  };
}
