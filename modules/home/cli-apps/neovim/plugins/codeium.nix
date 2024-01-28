{ ... }: {
  programs.nixvim.plugins =
    {
      codeium-vim = {
        enable = true;

        filetypes = {
          "c" = true;
          "cpp" = true;
          "csharp" = true;
          "go" = true;
          "java" = true;
          "javascript" = true;
          "javascriptreact" = true;
          "nix" = true;
          "python" = true;
          "rust" = true;
          "typescript" = true;
          "typescriptreact" = true;
        };
      };
    };
}
