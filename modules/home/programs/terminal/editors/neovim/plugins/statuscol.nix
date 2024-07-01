_: {
  programs.nixvim = {
    plugins.statuscol = {
      enable = true;

      settings = {
        relculright = true;

        segments = [
          {
            hl = "FoldColumn";
            text = [
              {
                __raw = # lua
                  "require('statuscol.builtin').foldfunc";
              }
            ];
            click = "v:lua.ScFa";
          }
          {
            text = null;
            sign = {
              name = [ ".*" ];
              namespace = [ ".*" ];
              text = [ ".*" ];
              maxwidth = 2;
              auto = true;
            };
            click = "v:lua.ScSa";
          }
          {
            text = [
              " "
              {
                __raw = # lua
                  "require('statuscol.builtin').lnumfunc";
              }
              " "
            ];
            click = "v:lua.ScLa";
          }
          {
            text = null;
            sign = {
              name = [ ".*" ];
              maxwidth = 2;
              colwidth = 1;
              auto = true;
              wrap = true;
            };
            click = "v:lua.ScSa";
          }
        ];
      };
    };
  };
}
