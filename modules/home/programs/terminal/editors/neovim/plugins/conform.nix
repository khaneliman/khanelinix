{ lib, pkgs, ... }:
{
  programs.nixvim = {
    extraConfigLuaPre = # lua
      ''
        local slow_format_filetypes = {}

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
          bang = true,
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

        formatOnSave = # lua
          ''
            function(bufnr)
              if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
              end

              if slow_format_filetypes[vim.bo[bufnr].filetype] then
                return
              end

              local function on_format(err)
                if err and err:match("timeout$") then
                  slow_format_filetypes[vim.bo[bufnr].filetype] = true
                end
              end

              return { timeout_ms = 200, lsp_fallback = true }, on_format
             end
          '';

        formatAfterSave = # lua
          ''
            function(bufnr)
              if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
              end

              if not slow_format_filetypes[vim.bo[bufnr].filetype] then
                return
              end

              return { lsp_fallback = true }
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
          bash = [
            "shellcheck"
            "shellharden"
            "shfmt"
          ];
          bicep = [ "bicep" ];
          c = [ "clang_format" ];
          cmake = [ "cmake-format" ];
          cpp = [ "clang_format" ];
          cs = [ "csharpier" ];
          css = [ "stylelint" ];
          fish = [ "fish_indent" ];
          fsharp = [ "fantomas" ];
          javascript = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          json = [ "jq" ];
          lua = [ "stylua" ];
          markdown = [ "deno_fmt" ];
          nix = [ "nixfmt" ];
          python = [
            "isort"
            "black"
          ];
          rust = [ "rustfmt" ];
          sh = [
            "shellcheck"
            "shellharden"
            "shfmt"
          ];
          sql = [ "sqlfluff" ];
          swift = [ "swift_format" ];
          terraform = [ "terraform_fmt" ];
          toml = [ "taplo" ];
          typescript = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          xml = [
            "xmlformat"
            "xmllint"
          ];
          yaml = [ "yamlfmt" ];
          zig = [ "zigfmt" ];
          "_" = [
            "squeeze_blanks"
            "trim_whitespace"
            "trim_newlines"
          ];
        };

        formatters = {
          black = {
            command = lib.getExe pkgs.black;
          };
          bicep = {
            command = lib.getExe pkgs.bicep;
          };
          cmake-format = {
            command = lib.getExe pkgs.cmake-format;
          };
          csharpier = {
            command = lib.getExe pkgs.csharpier;
          };
          deno_fmt = {
            command = lib.getExe pkgs.deno;
          };
          isort = {
            command = lib.getExe pkgs.isort;
          };
          fantomas = {
            command = lib.getExe pkgs.fantomas;
          };
          jq = {
            command = lib.getExe pkgs.jq;
          };
          nixfmt = {
            command = lib.getExe pkgs.nixfmt-rfc-style;
          };
          prettierd = {
            command = lib.getExe pkgs.prettierd;
          };
          rustfmt = {
            command = lib.getExe pkgs.rustfmt;
          };
          shellcheck = {
            command = lib.getExe pkgs.shellcheck;
          };
          shfmt = {
            command = lib.getExe pkgs.shfmt;
          };
          shellharden = {
            command = lib.getExe pkgs.shellharden;
          };
          sqlfluff = {
            command = lib.getExe pkgs.sqlfluff;
          };
          squeeze_blanks = {
            comamnd = lib.getExe' pkgs.coreutils "cat";
          };
          stylelint = {
            command = lib.getExe pkgs.stylelint;
          };
          stylua = {
            command = lib.getExe pkgs.stylua;
          };
          swift_format = {
            command = lib.getExe pkgs.swift-format;
          };
          taplo = {
            command = lib.getExe pkgs.taplo;
          };
          terraform_fmt = {
            command = lib.getExe pkgs.terraform;
          };
          xmlformat = {
            command = lib.getExe pkgs.xmlformat;
          };
          yamlfmt = {
            command = lib.getExe pkgs.yamlfmt;
          };
          zigfmt = {
            command = lib.getExe pkgs.zig;
          };
        };
      };
    };
  };
}
