_: {
  programs.nixvim = {
    plugins = {
      rustaceanvim = {
        enable = true;

        dap = {
          autoloadConfigurations = true;
        };

        server = {
          settings = {
            cargo = {
              buildScripts.enable = true;
              features = "all";
            };

            diagnostics = {
              enable = true;
              styleLints.enable = true;
            };

            checkOnSave = true;
            check = {
              command = "clippy";
              features = "all";
            };

            files = {
              excludeDirs = [
                ".cargo"
                ".direnv"
                ".git"
                "node_modules"
                "target"
              ];
            };

            inlayHints = {
              bindingModeHints.enable = true;
              closureStyle = "rust_analyzer";
              closureReturnTypeHints.enable = "always";
              discriminantHints.enable = "always";
              expressionAdjustmentHints.enable = "always";
              implicitDrops.enable = true;
              lifetimeElisionHints.enable = "always";
              rangeExclusiveHints.enable = true;
            };

            procMacro = {
              enable = true;
            };

            rustc.source = "discover";
          };
        };
      };
    };
  };
}
