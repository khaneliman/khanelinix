{ pkgs, lib, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-gdb
    ];

    plugins = {
      dap = {
        enable = true;

        adapters = {
          executables = {
            gdb = {
              command = "gdb";
              args = [ "-i" "dap" ];
            };

            lldb = {
              # command = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
              command = "${pkgs.lldb}/bin/lldb-vscode";
            };
          };
        };

        configurations = {
          c = [
            {
              name = "Launch";
              type = "gdb";
              request = "launch";
              program.__raw = ''
                function()
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
                end'';
              cwd = ''\$\{workspaceFolder}'';
              stopOnEntry = false;
            }
          ];
          rust = [
            {
              name = "Launch";
              type = "lldb";
              request = "launch";
              program.__raw = ''
                function()
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
                end'';
              cwd = ''\$\{workspaceFolder}'';
              stopOnEntry = false;
            }
          ];
        };

        extensions = {
          dap-ui = {
            enable = true;
          };

          dap-virtual-text = {
            enable = true;
          };
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>dE";
        lua = true;
        action = /*lua*/ ''
          function()
            vim.ui.input({ prompt = "Expression: " }, function(expr)
              if expr then require("dapui").eval(expr, { enter = true }) end
            end)
          end
        '';
        options = {
          desc = "Evaluate Input";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>du";
        lua = true;
        action = /*lua*/ ''
          function() require("dapui").toggle() end
        '';
        options = {
          desc = "Toggle Debugger UI";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>dh";
        lua = true;
        action = /*lua*/ ''
          function() require("dap.ui.widgets").hover() end
        '';
        options = {
          desc = "Debugger Hover";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>dE";
        lua = true;
        action = /*lua*/ ''
          function() require("dapui").eval() end
        '';
        options = {
          desc = "Evaluate Input";
          silent = true;
        };
      }
    ];
  };
}
