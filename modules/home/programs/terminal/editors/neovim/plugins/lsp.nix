{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkIf;
in
{
  programs.nixvim = {
    extraConfigLuaPre = # lua
      ''
        vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticError", linehl = "", numhl = "" })
        vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
        vim.fn.sign_define("DiagnosticSignHint", { text = " 󰌵", texthl = "DiagnosticHint", linehl = "", numhl = "" })
        vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
      '';

    plugins = {
      lspkind.enable = true;
      lsp-lines.enable = true;
      lsp-format.enable = mkIf (!config.programs.nixvim.plugins.conform-nvim.enable) true;

      # TODO: set up autocmd to reconfigure data with each project
      nvim-jdtls = {
        enable = true;
        configuration = "${config.xdg.cacheHome}/jdtls/config";
        data = "${config.xdg.cacheHome}/jdtls/workspace";
      };

      lsp = {
        enable = true;

        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>lp" = "goto_prev";
            "<leader>ln" = "goto_next";
          };

          extra = [
            {
              action = # lua
                ''
                  function()
                    vim.lsp.buf.format({
                      async = true,
                      range = {
                        ["start"] = vim.api.nvim_buf_get_mark(0, "<"),
                        ["end"] = vim.api.nvim_buf_get_mark(0, ">"),
                      }
                    })
                  end
                '';
              lua = true;
              mode = "v";
              key = "<leader>lf";
              options = {
                desc = "Format selection";
              };
            }
          ];

          lspBuf = {
            "<leader>la" = "code_action";
            "<leader>ld" = "definition";
            "<leader>lf" = "format";
            "<leader>lD" = "references";
            "<leader>lt" = "type_definition";
            "<leader>li" = "implementation";
            "<leader>lh" = "hover";
            "<leader>lr" = "rename";
          };
        };

        servers = {
          bashls = {
            enable = true;
            filetypes = [
              "sh"
              "bash"
            ];
          };

          ccls = {
            enable = true;
            filetypes = [
              "c"
              "cpp"
              "objc"
              "objcpp"
            ];

            initOptions.compilationDatabaseDirectory = "build";
          };

          clangd = {
            enable = false;
            filetypes = [
              "c"
              "cpp"
              "objc"
              "objcpp"
            ];
          };

          csharp-ls = {
            enable = true;
            filetypes = [ "cs" ];
          };

          dockerls = {
            enable = true;
            filetypes = [ "dockerfile" ];
          };

          eslint = {
            enable = true;
            filetypes = [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
            ];
          };

          fsautocomplete = {
            enable = true;
            filetypes = [ "fsharp" ];
          };

          html = {
            enable = true;
            filetypes = [ "html" ];
          };

          java-language-server = {
            enable = mkIf (!config.programs.nixvim.plugins.nvim-jdtls.enable) true;
            filetypes = [ "java" ];
          };

          jsonls = {
            enable = true;
            filetypes = [
              "json"
              "jsonc"
            ];
          };

          lua-ls = {
            enable = true;
            filetypes = [ "lua" ];
          };

          nil_ls = {
            enable = true;
            filetypes = [ "nix" ];
            settings.formatting.command = [ "${getExe pkgs.nixfmt-rfc-style}" ];
          };

          pyright = {
            enable = true;
            filetypes = [ "python" ];
          };

          rust-analyzer = {
            enable = mkIf (!config.programs.nixvim.plugins.rustaceanvim.enable) true;
            filetypes = [ "rust" ];
            installCargo = true;
            installRustc = true;

            settings = {
              diagnostics = {
                enable = true;
                # experimental.enable = true;
                styleLints.enable = true;
              };

              files = {
                excludeDirs = [
                  ".direnv"
                  "rust/.direnv"
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
            };
          };

          taplo = {
            enable = true;
            filetypes = [ "toml" ];
          };

          tsserver = {
            enable = true;
            filetypes = [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
            ];
          };

          yamlls = {
            enable = true;
            filetypes = [ "yaml" ];
          };
        };
      };

      which-key.registrations."<leader>l" = {
        mode = "v";
        name = "  LSP";
      };
    };
  };
}
