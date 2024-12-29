{ pkgs, lib, ... }:
let
  inherit (lib) getExe getExe';
in
{
  programs.helix.languages = {
    language =
      let
        deno = lang: {
          command = getExe pkgs.deno;
          args = [
            "fmt"
            "-"
            "--ext"
            lang
          ];
        };

        prettier = lang: {
          command = getExe pkgs.nodePackages.prettier;
          args = [
            "--parser"
            lang
          ];
        };
        prettierLangs = map (e: {
          name = e;
          formatter = prettier e;
        });
        langs = [
          "css"
          "scss"
          "html"
        ];
      in
      [
        {
          name = "bash";
          auto-format = true;
          formatter = {
            command = getExe pkgs.shfmt;
            args = [
              "-i"
              "2"
              "-"
            ];
          };
        }
        {
          name = "clojure";
          injection-regex = "(clojure|clj|edn|boot|yuck)";
          file-types = [
            "clj"
            "cljs"
            "cljc"
            "clje"
            "cljr"
            "cljx"
            "edn"
            "boot"
            "yuck"
          ];
        }
        {
          name = "javascript";
          auto-format = true;
          language-servers = [
            "dprint"
            "typescript-language-server"
          ];
        }
        {
          name = "json";
          formatter = deno "json";
        }
        {
          name = "markdown";
          auto-format = true;
          formatter = deno "md";
        }
        {
          name = "typescript";
          auto-format = true;
          language-servers = [
            "dprint"
            "typescript-language-server"
          ];
        }
      ]
      ++ prettierLangs langs;

    language-server = {
      bash-language-server = {
        command = getExe pkgs.bash-language-server;
        args = [ "start" ];
      };

      clangd = {
        command = getExe' pkgs.clang-tools "clangd";
        clangd.fallbackFlags = [ "-std=c++2b" ];
      };

      deno-lsp = {
        command = getExe pkgs.deno;
        args = [ "lsp" ];
        environment.NO_COLOR = "1";
        config.deno = {
          enable = true;
          lint = true;
          unstable = true;
          suggest = {
            completeFunctionCalls = false;
            imports = {
              hosts."https://deno.land" = true;
            };
          };
          inlayHints = {
            enumMemberValues.enabled = true;
            functionLikeReturnTypes.enabled = true;
            parameterNames.enabled = "all";
            parameterTypes.enabled = true;
            propertyDeclarationTypes.enabled = true;
            variableTypes.enabled = true;
          };
        };
      };

      dprint = {
        command = getExe pkgs.dprint;
        args = [ "lsp" ];
      };

      nil = {
        command = getExe pkgs.nil;
        config.nil.formatting.command = [
          "${getExe pkgs.nixfmt-rfc-style}"
          "-q"
        ];
      };

      typescript-language-server = {
        command = getExe pkgs.nodePackages.typescript-language-server;
        args = [ "--stdio" ];
        config =
          let
            inlayHints = {
              includeInlayEnumMemberValueHints = true;
              includeInlayFunctionLikeReturnTypeHints = true;
              includeInlayFunctionParameterTypeHints = true;
              includeInlayParameterNameHints = "all";
              includeInlayParameterNameHintsWhenArgumentMatchesName = true;
              includeInlayPropertyDeclarationTypeHints = true;
              includeInlayVariableTypeHints = true;
            };
          in
          {
            typescript-language-server.source = {
              addMissingImports.ts = true;
              fixAll.ts = true;
              organizeImports.ts = true;
              removeUnusedImports.ts = true;
              sortImports.ts = true;
            };

            typescript = {
              inherit inlayHints;
            };
            javascript = {
              inherit inlayHints;
            };

            hostInfo = "helix";
          };
      };

      vscode-css-language-server = {
        command = lib.getExe' pkgs.vscode-langservers-extracted "vscode-css-language-server";
        args = [ "--stdio" ];
        config = {
          provideFormatter = true;
          css.validate.enable = true;
          scss.validate.enable = true;
        };
      };
    };
  };
}
