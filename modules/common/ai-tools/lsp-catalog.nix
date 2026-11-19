{
  lib,
  pkgs,
  userName,
  nixdContext ? null,
}:
let
  inherit (lib) getExe getExe' nameValuePair;

  # OpenCode consumes extensions in list order; Claude and Copilot use language maps.
  toLang = language: map (extension: nameValuePair extension language);

  pythonExtensions = toLang "python" [
    ".py"
    ".pyi"
    ".pyw"
  ];
  markdownExtensions = toLang "markdown" [
    ".md"
    ".markdown"
    ".mdx"
  ];

  nixdExprs = import ../nixd (
    nixdContext
    // {
      inherit (pkgs.stdenv.hostPlatform) system;
    }
  );
in
{
  nixd = {
    command = getExe pkgs.nixd;
    extensions = toLang "nix" [ ".nix" ];
    initializationOptions = {
      formatting.command = [ (getExe pkgs.nixfmt) ];
    }
    // lib.optionalAttrs (nixdContext != null) {
      nixpkgs.expr = nixdExprs.nixpkgs;
      options = {
        nixos.expr = nixdExprs.nixosOptions;
        darwin.expr = nixdExprs.darwinOptions;
        home-manager.expr = nixdExprs.homeManagerOptions;
      };
    };
  };

  emmylua-ls = {
    command = getExe pkgs.emmylua-ls;
    extensions = toLang "lua" [ ".lua" ];
    initializationOptions.Lua = {
      diagnostics.globals = [
        "vim"
        "Sbar"
        "spoon"
      ];
      workspace.library = [
        "/nix/store/*/share/lua/5.1"
        "/etc/profiles/per-user/${userName}/share/lua/5.1"
      ];
    };
  };

  basedpyright = {
    command = getExe' pkgs.basedpyright "basedpyright-langserver";
    args = [ "--stdio" ];
    extensions = pythonExtensions;
  };

  ruff = {
    command = getExe pkgs.ruff;
    args = [ "server" ];
    extensions = pythonExtensions;
  };

  bashls = {
    command = getExe pkgs.bash-language-server;
    args = [ "start" ];
    extensions = toLang "shellscript" [
      ".sh"
      ".bash"
    ];
  };

  fish-lsp = {
    command = getExe pkgs.fish-lsp;
    extensions = toLang "fish" [ ".fish" ];
  };

  nushell = {
    command = getExe pkgs.nushell;
    args = [ "--lsp" ];
    extensions = toLang "nu" [ ".nu" ];
  };

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
    extensions =
      toLang "c" [ ".c" ]
      ++ toLang "cpp" [
        ".cpp"
        ".cc"
        ".cxx"
        ".c++"
      ]
      ++ toLang "c" [ ".h" ]
      ++ toLang "cpp" [
        ".hpp"
        ".hh"
        ".hxx"
        ".h++"
      ];
  };

  cmake = {
    command = getExe pkgs.cmake-language-server;
    extensions = toLang "cmake" [ ".cmake" ];
  };

  typescript = {
    command = getExe pkgs.typescript-language-server;
    args = [ "--stdio" ];
    extensions = [
      (nameValuePair ".ts" "typescript")
      (nameValuePair ".tsx" "typescriptreact")
      (nameValuePair ".js" "javascript")
      (nameValuePair ".jsx" "javascriptreact")
      (nameValuePair ".mjs" "javascript")
      (nameValuePair ".cjs" "javascript")
      (nameValuePair ".mts" "typescript")
      (nameValuePair ".cts" "typescript")
    ];
  };

  cssls = {
    command = getExe' pkgs.vscode-langservers-extracted "vscode-css-language-server";
    args = [ "--stdio" ];
    extensions = [
      (nameValuePair ".css" "css")
      (nameValuePair ".scss" "scss")
      (nameValuePair ".less" "less")
    ];
  };

  html = {
    command = getExe' pkgs.vscode-langservers-extracted "vscode-html-language-server";
    args = [ "--stdio" ];
    extensions = toLang "html" [
      ".html"
      ".htm"
    ];
  };

  jsonls = {
    command = getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server";
    args = [ "--stdio" ];
    extensions = [
      (nameValuePair ".json" "json")
      (nameValuePair ".jsonc" "jsonc")
    ];
  };

  yamlls = {
    command = getExe pkgs.yaml-language-server;
    args = [ "--stdio" ];
    extensions = toLang "yaml" [
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
    extensions = toLang "toml" [ ".toml" ];
  };

  sqls = {
    command = getExe pkgs.sqls;
    extensions = toLang "sql" [ ".sql" ];
  };

  helm-ls = {
    command = getExe pkgs.helm-ls;
    args = [ "serve" ];
    # Helm keys on the `helm` filetype (templates/*.yaml + *.tpl); only .tpl
    # is uniquely mappable here without stealing plain YAML from yamlls.
    extensions = toLang "helm" [ ".tpl" ];
  };

  gopls = {
    command = getExe pkgs.gopls;
    extensions = [
      (nameValuePair ".go" "go")
      (nameValuePair ".mod" "go.mod")
      (nameValuePair ".sum" "go.sum")
    ];
  };

  rust-analyzer = {
    command = getExe pkgs.rust-analyzer;
    extensions = toLang "rust" [ ".rs" ];
  };

  csharp = {
    command = getExe pkgs.roslyn-ls;
    extensions = toLang "csharp" [
      ".cs"
      ".csx"
      ".cake"
    ];
  };

  java = {
    command = getExe' pkgs.jdt-language-server "jdtls";
    extensions = toLang "java" [ ".java" ];
  };

  marksman = {
    command = getExe pkgs.marksman;
    extensions = markdownExtensions;
  };

  typos-lsp = {
    command = getExe pkgs.typos-lsp;
    extensions = markdownExtensions ++ toLang "plaintext" [ ".txt" ];
    initializationOptions.diagnosticSeverity = "Warning";
  };
}
