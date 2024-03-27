{ lib, pkgs, ... }:
let
  codelldb-config = {
    name = "Launch";
    type = "codelldb";
    request = "launch";
    program.__raw = ''
      function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
      end
    '';
    cwd = ''\$\{workspaceFolder}'';
    stopOnEntry = false;
  };

  coreclr-config = {
    type = "coreclr";
    name = "launch - netcoredbg";
    request = "launch";
    program__raw = ''
      function()
        if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
          vim.g.dotnet_build_project()
        end

        return vim.g.dotnet_get_dll_path()
      end'';
    cwd = ''\$\{workspaceFolder}'';
  };

  gdb-config = {
    name = "Launch";
    type = "gdb";
    request = "launch";
    program.__raw = ''
      function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
      end'';
    cwd = ''\$\{workspaceFolder}'';
    stopOnEntry = false;
  };

  lldb-config = {
    name = "Launch";
    type = "lldb";
    request = "launch";
    program.__raw = ''
      function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
      end'';
    cwd = ''\$\{workspaceFolder}'';
    stopOnEntry = false;
  };
in
{
  home.packages = with pkgs; [
    netcoredbg
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.gdb
  ];

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
              command = "${pkgs.lldb}/bin/lldb-vscode";
            };

            coreclr = {
              command = "${lib.getExe pkgs.netcoredbg}";
              args = [
                "--interpreter=vscode"
              ];
            };
          };

          servers = {
            codelldb = lib.mkIf pkgs.stdenv.isLinux {
              port = 13000;
              executable = {
                command = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
                args = [
                  "--port"
                  "13000"
                ];
              };
            };
          };
        };

        configurations = {
          c = [
            lldb-config
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [ gdb-config ];

          cpp = [
            lldb-config
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [ codelldb-config ];

          cs = [
            coreclr-config
          ];

          fsharp = [
            coreclr-config
          ];

          rust = [
            lldb-config
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [ codelldb-config ];
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
