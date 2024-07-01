{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  codelldb-config = {
    name = "Launch (CodeLLDB)";
    type = "codelldb";
    request = "launch";
    program.__raw = # lua
      ''
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
    program__raw = # lua
      ''
        function()
          if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
            vim.g.dotnet_build_project()
          end

          return vim.g.dotnet_get_dll_path()
        end'';
    cwd = ''\$\{workspaceFolder}'';
  };

  gdb-config = {
    name = "Launch (GDB)";
    type = "gdb";
    request = "launch";
    program.__raw = # lua
      ''
        function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
        end'';
    cwd = ''\$\{workspaceFolder}'';
    stopOnEntry = false;
  };

  lldb-config = {
    name = "Launch (LLDB)";
    type = "lldb";
    request = "launch";
    program.__raw = # lua
      ''
        function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
        end'';
    cwd = ''\$\{workspaceFolder}'';
    stopOnEntry = false;
  };

  sh-config = lib.mkIf pkgs.stdenv.isLinux {
    type = "bashdb";
    request = "launch";
    name = "Launch (BashDB)";
    showDebugOutput = true;
    pathBashdb = "${lib.getExe pkgs.bashdb}";
    pathBashdbLib = "${pkgs.bashdb}/share/basdhb/lib/";
    trace = true;
    file = ''\$\{file}'';
    program = ''\$\{file}'';
    cwd = ''\$\{workspaceFolder}'';
    pathCat = "cat";
    pathBash = "${lib.getExe pkgs.bash}";
    pathMkfifo = "mkfifo";
    pathPkill = "pkill";
    args = { };
    env = { };
    terminalKind = "integrated";
  };
in
{
  home.packages =
    with pkgs;
    [
      coreutils
      lldb
      netcoredbg
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.gdb
      pkgs.bashdb
    ];

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ nvim-gdb ];

    plugins = {
      dap = {
        enable = true;

        adapters = {
          executables = {
            bashdb = lib.mkIf pkgs.stdenv.isLinux { command = "${lib.getExe pkgs.bashdb}"; };

            cppdbg = {
              command = "gdb";
              args = [
                "-i"
                "dap"
              ];
            };

            gdb = {
              command = "gdb";
              args = [
                "-i"
                "dap"
              ];
            };

            lldb = {
              command = "${pkgs.lldb}/bin/lldb-vscode";
            };

            coreclr = {
              command = "${lib.getExe pkgs.netcoredbg}";
              args = [ "--interpreter=vscode" ];
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
          c = [ lldb-config ] ++ lib.optionals pkgs.stdenv.isLinux [ gdb-config ];

          cpp =
            [ lldb-config ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              gdb-config
              codelldb-config
            ];

          cs = [ coreclr-config ];

          fsharp = [ coreclr-config ];

          rust = [ lldb-config ] ++ lib.optionals pkgs.stdenv.isLinux [ codelldb-config ];

          sh = lib.optionals pkgs.stdenv.isLinux [ sh-config ];
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

      which-key.registrations."<leader>d" =
        mkIf config.programs.nixvim.plugins.dap.extensions.dap-ui.enable
          {
            mode = "v";
            name = "  Debug";
          };
    };

    keymaps = lib.optionals config.programs.nixvim.plugins.dap.extensions.dap-ui.enable [
      {
        mode = "n";
        key = "<leader>db";
        action.__raw = # lua
          ''
            function() 
              require("dap").toggle_breakpoint() 
            end
          '';
        options = {
          desc = "Breakpoint toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>dc";
        action.__raw = # lua
          ''
            function() 
              require("dap").continue() 
            end
          '';
        options = {
          desc = "Continue Debugging (Start)";
          silent = true;
        };
      }
      {
        mode = "v";
        key = "<leader>dE";
        action.__raw = # lua
          ''
            function() require("dapui").eval() end
          '';
        options = {
          desc = "Evaluate Input";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>dE";
        action.__raw = # lua
          ''
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
        key = "<leader>dh";
        action.__raw = # lua
          ''
            function() require("dap.ui.widgets").hover() end
          '';
        options = {
          desc = "Debugger Hover";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>do";
        action.__raw = # lua
          ''
            function() 
              require("dap").step_out() 
            end
          '';
        options = {
          desc = "Step Out";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ds";
        action.__raw = # lua
          ''
            function() 
              require("dap").step_over() 
            end
          '';
        options = {
          desc = "Step Over";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>dS";
        action.__raw = # lua
          ''
            function() 
              require("dap").step_into() 
            end
          '';
        options = {
          desc = "Step Into";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>du";
        action.__raw = # lua
          ''
            function() 
              require('dap.ext.vscode').load_launchjs(nil, {})
              require("dapui").toggle() 
            end
          '';
        options = {
          desc = "Toggle Debugger UI";
          silent = true;
        };
      }
    ];
  };
}
