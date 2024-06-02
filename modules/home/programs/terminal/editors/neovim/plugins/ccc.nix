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
            filetypes = [ "colorPickerFts" ];
          };
          pickers = [
            ''require("ccc").picker.hex''
            ''require("ccc").picker.css_rgb''
            ''require("ccc").picker.css_hsl''
            ''
              require("ccc").picker.ansi_escape {
                              meaning1 = "bright"
                            }''
          ];
          alpha_show = "hide";
          recognize = {
            output = true;
          };
          inputs = [ "require('ccc').input.hsl" ];
          outputs = [
            "require('ccc').output.css_hsl"
            "require('ccc').output.css_rgb"
            "require('ccc').output.hex"
          ];
          convert = [
            [
              "require('ccc').picker.hex"
              "require('ccc').output.css_hsl"
            ]
            [
              "require('ccc').picker.css_rgb"
              "require('ccc').output.css_hsl"
            ]
            [
              "require('ccc').picker.css_hsl"
              "require('ccc').output.hex"
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
          desc = "Color Picker toggle";
          silent = true;
        };
      }
    ];
  };
}
