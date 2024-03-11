_: {
  programs.nixvim.plugins = {
    conform-nvim = {
      enable = true;

      formatOnSave = {
        lspFallback = true;
        timeoutMs = 500;
      };

      # NOTE:
      # Conform will run multiple formatters sequentially
      # [ "1" "2" "3"]
      # Use a sub-list to run only the first available formatter
      # [ ["1"] ["2"] ["3"] ]
      # Use the "*" filetype to run formatters on all filetypes.
      # Use the "_" filetype to run formatters on filetypes that don't
      # have other formatters configured.
      formattersByFt = {
        bash = [ "shellcheck" "shellharden" "shfmt" ];
        c = [ "clang_format" ];
        cpp = [ "clang_format" ];
        cs = [ "csharpier" ];
        fish = [ "fish_indent" ];
        json = [ "jq" ];
        lua = [ "stylua" ];
        nix = [ "nixpkgs_fmt" ];
        python = [ "isort" "black" ];
        javascript = [ [ "prettierd" "prettier" ] ];
        rust = [ "rustfmt" ];
        sh = [ "shellcheck" "shellharden" "shfmt" ];
        sql = [ "sqlfmt" ];
        swift = [ "swiftformat" ];
        terraform = [ "terraform_fmt" ];
        toml = [ "taplo" ];
        xml = [ "xmllint" ];
        yaml = [ "yamlfmt" ];
        zig = [ "zigfmt" ];
        "*" = [ "codespell" ];
        "_" = [ "trim_whitespace" ];
      };
    };
  };
}
