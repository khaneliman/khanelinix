{ ... }: {
  programs.nixvim = {
    plugins = {
      lsp = {
        enable = true;

        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };

          lspBuf = {
            gd = "definition";
            gD = "references";
            gt = "type_definition";
            gi = "implementation";
            K = "hover";
            "<F2>" = "rename";
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
          };
          clangd = {
            enable = true;
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
          };
          pyright = {
            enable = true;
            filetypes = [ "python" ];
          };
          rust-analyzer = {
            enable = true;
            filetypes = [ "rust" ];
            installCargo = true;
            installRustc = true;
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
