_: {
  programs.nixvim = {
    extraConfigLuaPre = /* lua */ ''
      vim.api.nvim_create_user_command("FormatDisable", function(args)
         if args.bang then
          -- FormatDisable! will disable formatting just for this buffer
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })
      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })
      vim.api.nvim_create_user_command("FormatToggle", function(args)
        if args.bang then
          -- Toggle formatting for current buffer
          vim.b.disable_autoformat = not vim.b.disable_autoformat
        else
          -- Toggle formatting globally
          vim.g.disable_autoformat = not vim.g.disable_autoformat
        end
      end, {
        desc = "Toggle autoformat-on-save",
      })
    '';

    # FIX: doesn't work for some reason with nixvim generated use command
    # userCommands = {
    #   "FormatDisable" = {
    #     command = /*lua*/ ''
    #       function FormatDisable(args)
    #          if args.bang then
    #           vim.b.disable_autoformat = true
    #          else
    #           vim.g.disable_autoformat = true
    #          end
    #       end
    #     '';
    #     desc = "Disable autoformat-on-save";
    #     bang = true;
    #   };
    #   "FormatEnable" = {
    #     command = /*lua*/ ''
    #       function FormatEnable()
    #         vim.b.disable_autoformat = false
    #         vim.g.disable_autoformat = false
    #       end
    #     '';
    #     desc = "Re-enable autoformat-on-save";
    #   };
    # };

    plugins = {
      conform-nvim = {
        enable = true;

        formatOnSave = /*lua*/ ''
          function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
              return
            end
            return { timeout_ms = 500, lsp_fallback = true }
          end
        '';

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
  };
}
