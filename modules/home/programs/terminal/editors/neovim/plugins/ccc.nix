_: {
  programs.nixvim = {
    plugins = {
      ccc = {
        enable = true;

        settings = {
          highlighter = {
            auto_enable = true;
            max_byte = 2 * 1024 * 1024;
            lsp = true;
            filetypes.__raw = "colorPickerFts";
          };
          pickers = [
            { __raw = ''require("ccc").picker.hex''; }
            { __raw = ''require("ccc").picker.css_rgb''; }
            { __raw = ''require("ccc").picker.css_hsl''; }
            {
              __raw = ''
                require("ccc").picker.ansi_escape {
                  meaning1 = "bright"
                }'';
            }
          ];
          alpha_show = "hide";
          recognize = {
            output = true;
          };
          inputs = [ { __raw = "require('ccc').input.hsl"; } ];
          outputs = [
            { __raw = "require('ccc').output.css_hsl"; }
            { __raw = "require('ccc').output.css_rgb"; }
            { __raw = "require('ccc').output.hex"; }
          ];
          convert = [
            [
              { __raw = "require('ccc').picker.hex"; }
              { __raw = "require('ccc').output.css_hsl"; }
            ]
            [
              { __raw = "require('ccc').picker.css_rgb"; }
              { __raw = "require('ccc').output.css_hsl"; }
            ]
            [
              { __raw = "require('ccc').picker.css_hsl"; }
              { __raw = "require('ccc').output.hex"; }
            ]
          ];
          mappings = {
            "q".__raw = "require('ccc').mapping.quit";
            "L".__raw = "require('ccc').mapping.increase10";
            "H".__raw = "require('ccc').mapping.decrease10";
          };
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>up";
        action = ":CccPick<CR>";
        options = {
          desc = "Toggle Color Picker";
          silent = true;
        };
      }
    ];
  };
}
