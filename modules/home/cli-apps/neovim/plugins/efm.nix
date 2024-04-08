_: {
  programs.nixvim.plugins = {

    lsp.servers.efm = {
      enable = true;
      extraOptions.init_options = {
        documentFormatting = false;
        documentRangeFormatting = false;
        hover = true;
        documentSymbol = true;
        codeAction = true;
        completion = true;
      };
    };

    efmls-configs = {
      enable = true;

      setup = {
        all.linter = [ "codespell" ];
        bash.linter = [ "shellcheck" ];
        c.linter = [ "clang_tidy" ];
        "c++".linter = [
          "clang_tidy"
          "cppcheck"
          "cpplint"
        ];
        "c#".linter = [ "mcs" ];
        css.linter = [ "stylelint" ];
        gitcommit.linter = [ "gitlint" ];
        javascript.linter = [ "eslint_d" ];
        json.linter = [ "jq" ];
        lua.linter = [ "luacheck" ];
        markdown.linter = [ "markdownlint" ];
        nix.linter = [ "statix" ];
        python.linter = [ "pylint" ];
        scss.linter = [ "stylelint" ];
        sh.linter = [ "shellcheck" ];
        sql.linter = [ "sqlfluff" ];
        typecript.linter = [ "eslint_d" ];
        yaml.linter = [ "yamllint" ];
      };
    };
  };
}
