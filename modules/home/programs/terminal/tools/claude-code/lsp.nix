# Claude Code LSP (Language Server Protocol) configuration module.
#
# Slim, diagnostics-first roster: servers are chosen for the errors/warnings
# they surface to Claude, not navigation/completion/spelling. Claude Code's
# `.lsp.json` is flat and attaches *every* server matching an extension - it has
# none of the runtime LspAttach arbitration khanelivim uses - so overlapping
# linters/formatters (biome, eslint, stylelint, tailwindcss on web) and prose
# grammar (harper) are intentionally left out. At most one diagnostic server per
# file type, plus a second only where it adds distinct diagnostics: python
# (basedpyright types + ruff lint) and markdown (marksman broken-link warnings +
# typos misspellings). typos is prose-scoped and raised to Warning severity so
# it contributes to the errors/warnings signal rather than emitting Hint noise.
#
# Choice-gated servers resolve to khanelivim's defaults (cpp=clangd,
# lua=emmylua-ls, nix=nixd, python=basedpyright, rust=rust-analyzer,
# csharp=roslyn-ls, ts=typescript-language-server).
{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    getExe
    getExe'
    genAttrs
    mkIf
    ;

  cfg = config.khanelinix.programs.terminal.tools.claude-code;

  # Map a list of file extensions to a single LSP language id.
  toLang = lang: exts: genAttrs exts (_: lang);

  # Flake-aware nixd exprs (cwd flake autodetection, falling back to khanelinix).
  nixdExprs = import (lib.getFile "modules/common/nixd") {
    inherit self;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  config = mkIf cfg.enable {
    programs.claude-code.lspServers = {
      # --- Nix ---
      nixd = {
        command = getExe pkgs.nixd;
        extensionToLanguage = toLang "nix" [ ".nix" ];
        initializationOptions = {
          nixpkgs.expr = nixdExprs.nixpkgs;
          formatting.command = [ (getExe pkgs.nixfmt) ];
          options = {
            nixos.expr = nixdExprs.nixosOptions;
            home-manager.expr = nixdExprs.homeManagerOptions;
          };
        };
      };

      # --- Lua ---
      emmylua-ls = {
        command = getExe pkgs.emmylua-ls;
        extensionToLanguage = toLang "lua" [ ".lua" ];
        initializationOptions.Lua = {
          diagnostics.globals = [
            "vim"
            "Sbar"
            "spoon"
          ];
          workspace.library = [
            "/nix/store/*/share/lua/5.1"
            "/etc/profiles/per-user/${config.khanelinix.user.name}/share/lua/5.1"
          ];
        };
      };

      # --- Python (basedpyright type-checks, ruff lints/formats) ---
      basedpyright = {
        command = getExe' pkgs.basedpyright "basedpyright-langserver";
        args = [ "--stdio" ];
        extensionToLanguage = toLang "python" [
          ".py"
          ".pyi"
          ".pyw"
        ];
      };

      ruff = {
        command = getExe pkgs.ruff;
        args = [ "server" ];
        extensionToLanguage = toLang "python" [
          ".py"
          ".pyi"
          ".pyw"
        ];
      };

      # --- Shell ---
      bashls = {
        command = getExe pkgs.bash-language-server;
        args = [ "start" ];
        extensionToLanguage = toLang "shellscript" [
          ".sh"
          ".bash"
        ];
      };

      fish-lsp = {
        command = getExe pkgs.fish-lsp;
        extensionToLanguage = toLang "fish" [ ".fish" ];
      };

      nushell = {
        command = getExe pkgs.nushell;
        args = [ "--lsp" ];
        extensionToLanguage = toLang "nu" [ ".nu" ];
      };

      # --- C / C++ ---
      clangd = {
        command = getExe' pkgs.clang-tools "clangd";
        args = [
          "--background-index"
          "--clang-tidy"
          "--header-insertion=iwyu"
          "--completion-style=detailed"
          "--function-arg-placeholders"
          "--fallback-style=llvm"
        ];
        initializationOptions = {
          usePlaceholders = true;
          completeUnimported = true;
          clangdFileStatus = true;
        };
        extensionToLanguage =
          (toLang "c" [
            ".c"
            ".h"
          ])
          // (toLang "cpp" [
            ".cpp"
            ".cc"
            ".cxx"
            ".c++"
            ".hpp"
            ".hh"
            ".hxx"
            ".h++"
          ]);
      };

      cmake = {
        command = getExe pkgs.cmake-language-server;
        extensionToLanguage = toLang "cmake" [ ".cmake" ];
      };

      # --- Web (one server per type: TS for scripts, cssls for styles, html) ---
      typescript = {
        command = getExe pkgs.typescript-language-server;
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
          ".js" = "javascript";
          ".jsx" = "javascriptreact";
          ".mjs" = "javascript";
          ".cjs" = "javascript";
          ".mts" = "typescript";
          ".cts" = "typescript";
        };
      };

      cssls = {
        command = getExe' pkgs.vscode-langservers-extracted "vscode-css-language-server";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".css" = "css";
          ".scss" = "scss";
          ".less" = "less";
        };
      };

      html = {
        command = getExe' pkgs.vscode-langservers-extracted "vscode-html-language-server";
        args = [ "--stdio" ];
        extensionToLanguage = toLang "html" [
          ".html"
          ".htm"
        ];
      };

      # --- Data / config ---
      jsonls = {
        command = getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".json" = "json";
          ".jsonc" = "jsonc";
        };
      };

      yamlls = {
        command = getExe pkgs.yaml-language-server;
        args = [ "--stdio" ];
        extensionToLanguage = toLang "yaml" [
          ".yaml"
          ".yml"
        ];
      };

      taplo = {
        command = getExe pkgs.taplo;
        args = [
          "lsp"
          "stdio"
        ];
        extensionToLanguage = toLang "toml" [ ".toml" ];
      };

      sqls = {
        command = getExe pkgs.sqls;
        extensionToLanguage = toLang "sql" [ ".sql" ];
      };

      helm-ls = {
        command = getExe pkgs.helm-ls;
        args = [ "serve" ];
        # Helm keys on the `helm` filetype (templates/*.yaml + *.tpl); only .tpl
        # is uniquely mappable here without stealing plain YAML from yamlls.
        extensionToLanguage = toLang "helm" [ ".tpl" ];
      };

      # --- Compiled languages ---
      gopls = {
        command = getExe pkgs.gopls;
        extensionToLanguage = {
          ".go" = "go";
          ".mod" = "go.mod";
          ".sum" = "go.sum";
        };
      };

      rust-analyzer = {
        command = getExe pkgs.rust-analyzer;
        extensionToLanguage = toLang "rust" [ ".rs" ];
      };

      csharp = {
        command = getExe pkgs.roslyn-ls;
        extensionToLanguage = toLang "csharp" [
          ".cs"
          ".csx"
          ".cake"
        ];
      };

      java = {
        command = getExe' pkgs.jdt-language-server "jdtls";
        extensionToLanguage = toLang "java" [ ".java" ];
      };

      # --- Docs (marksman: broken-link warnings; typos: misspellings) ---
      marksman = {
        command = getExe pkgs.marksman;
        extensionToLanguage = toLang "markdown" [
          ".md"
          ".markdown"
          ".mdx"
        ];
      };

      typos-lsp = {
        command = getExe pkgs.typos-lsp;
        extensionToLanguage =
          toLang "markdown" [
            ".md"
            ".markdown"
            ".mdx"
          ]
          // toLang "plaintext" [ ".txt" ];
        initializationOptions.diagnosticSeverity = "Warning";
      };
    };
  };
}
