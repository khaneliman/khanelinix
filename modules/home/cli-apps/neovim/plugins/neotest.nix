_: {
  programs.nixvim = {

    plugins.neotest = {
      enable = true;

      adapters = {
        dotnet = {
          enable = true;
        };

        java = {
          enable = true;
        };

        jest = {
          enable = true;
        };

        playwright = {
          enable = true;
        };

        rust = {
          enable = true;
        };
      };
    };
  };
}
