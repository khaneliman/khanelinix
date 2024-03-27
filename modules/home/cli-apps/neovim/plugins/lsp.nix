{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) getExe mkIf;
in
{
  programs.nixvim = {
    plugins = {
      lsp-format.enable = mkIf (!config.programs.nixvim.plugins.conform-nvim.enable) true;

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

      lsp = {
        enable = true;

        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>lp" = "goto_prev";
            "<leader>ln" = "goto_next";
          };

          lspBuf = {
            "<leader>la" = "code_action";
            "<leader>ld" = "definition";
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
            filetypes = [ "sh" "bash" ];
          };

          ccls = {
            enable = true;
            filetypes = [ "c" "cpp" "objc" "objcpp" ];

            initOptions.compilationDatabaseDirectory = "build";
          };

          clangd = {
            enable = false;
            filetypes = [ "c" "cpp" "objc" "objcpp" ];
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
            filetypes = [ "javascript" "javascriptreact" "typescript" "typescriptreact" ];
          };

          html = {
            enable = true;
            filetypes = [ "html" ];
          };

          java-language-server = {
            enable = true;
            filetypes = [ "java" ];
          };

          jsonls = {
            enable = true;
            filetypes = [ "json" ];
          };

          lua-ls = {
            enable = true;
            filetypes = [ "lua" ];
          };

          nil_ls = {
            enable = true;
            filetypes = [ "nix" ];
            settings.formatting.command = [ "${getExe pkgs.nixpkgs-fmt}" ];
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
              };

              inlayHints = {
                bindingModeHints.enable = true;
                closureStyle = "rust_analyzer";
                closureReturnTypeHints.enable = "always";
                discriminantHints.enable = "always";
                expressionAdjustmentHints. enable = "always";
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
            filetypes = [ "javascript" "javascriptreact" "typescript" "typescriptreact" ];
          };

          yamlls = {
            enable = true;
            filetypes = [ "yaml" ];
          };
        };
      };
    };
  };
}
