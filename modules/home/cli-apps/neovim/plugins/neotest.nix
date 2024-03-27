_: {
  programs.nixvim = {

    plugins.neotest = {
      enable = true;

      settings = {
        adapters = [
          ''require('rustaceanvim.neotest')''
        ];
      };

      adapters = {
        bash = {
          enable = true;
        };

        deno = {
          enable = true;
        };

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
      };
    };
  };
}
