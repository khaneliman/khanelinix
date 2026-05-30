{
  self,
  lib,
}:
let
  inherit (self.lib)
    base64
    file
    module
    theme
    ;
in
{
  # base64.decode
  testBase64DecodeHello = {
    expr = base64.decode "aGVsbG8=";
    expected = "hello";
  };

  testBase64DecodeNoPadding = {
    expr = base64.decode "Zm9vYmFy";
    expected = "foobar";
  };

  testBase64DecodeOnePad = {
    expr = base64.decode "Zm9vYmE=";
    expected = "fooba";
  };

  testBase64DecodeTwoPad = {
    expr = base64.decode "Zm9vYg==";
    expected = "foob";
  };

  # module.capitalize
  testCapitalizeWord = {
    expr = module.capitalize "hello";
    expected = "Hello";
  };

  testCapitalizeSingle = {
    expr = module.capitalize "a";
    expected = "A";
  };

  testCapitalizeEmpty = {
    expr = module.capitalize "";
    expected = "";
  };

  # module.boolToNum
  testBoolToNumTrue = {
    expr = module.boolToNum true;
    expected = 1;
  };

  testBoolToNumFalse = {
    expr = module.boolToNum false;
    expected = 0;
  };

  # module.enabled / module.disabled
  testEnabled = {
    expr = module.enabled;
    expected = {
      enable = true;
    };
  };

  testDisabled = {
    expr = module.disabled;
    expected = {
      enable = false;
    };
  };

  # module.enableForSystem keeps modules with no `systems` or a matching one.
  testEnableForSystem = {
    expr = module.enableForSystem "x86_64-linux" [
      { name = "any"; }
      {
        name = "darwin-only";
        systems = [ "aarch64-darwin" ];
      }
      {
        name = "linux-only";
        systems = [ "x86_64-linux" ];
      }
    ];
    expected = [
      { name = "any"; }
      {
        name = "linux-only";
        systems = [ "x86_64-linux" ];
      }
    ];
  };

  # module.mkOpt / module.mkBoolOpt resolve to module-system options.
  testMkOptDefault = {
    expr = (module.mkOpt' lib.types.int 5).default;
    expected = 5;
  };

  testMkBoolOptDefault = {
    expr = (module.mkBoolOpt' true).default;
    expected = true;
  };

  # module.default-attrs / module.force-attrs wrap values with merge priorities.
  testDefaultAttrsContent = {
    expr = (module.default-attrs { a = 1; }).a.content;
    expected = 1;
  };

  testDefaultAttrsPriority = {
    expr = (module.default-attrs { a = 1; }).a.priority;
    expected = 1000;
  };

  testForceAttrsPriority = {
    expr = (module.force-attrs { a = 1; }).a.priority;
    expected = 50;
  };

  # file.mergeAttrs (later sets win)
  testMergeAttrs = {
    expr = file.mergeAttrs [
      {
        a = 1;
        b = 1;
      }
      {
        b = 2;
        c = 3;
      }
    ];
    expected = {
      a = 1;
      b = 2;
      c = 3;
    };
  };

  testMergeAttrsEmpty = {
    expr = file.mergeAttrs [ ];
    expected = { };
  };

  # theme helpers
  testThemeMkColorScheme = {
    expr = theme.mkColorScheme "test" { bg = "#000000"; };
    expected = {
      name = "test";
      colors = {
        bg = "#000000";
      };
      type = "colorScheme";
    };
  };

  testThemeGetColors = {
    expr = theme.getColors {
      colors = {
        fg = "#ffffff";
      };
    };
    expected = {
      fg = "#ffffff";
    };
  };

  testThemeGetColorsMissing = {
    expr = theme.getColors { };
    expected = { };
  };

  testThemeVariants = {
    expr = theme.variants;
    expected = {
      light = "light";
      dark = "dark";
    };
  };
}
