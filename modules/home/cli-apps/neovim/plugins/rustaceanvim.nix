_: {
  programs.nixvim = {
    plugins = {
      rustaceanvim = {
        enable = true;

        dap = {
          autoloadConfigurations = true;
        };

        server.settings = {
          cargo.features = "all";
          checkOnSave = true;
          check.command = "clippy";
          files = {
            excludeDirs = [ ".direnv" ];
          };
          rustc.source = "discover";
        };
      };
    };
  };
}
