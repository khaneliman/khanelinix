{ config, ... }: {
  programs.nixvim = {
    filetype.pattern = {
      ".*/hypr/.*%.conf" = "hyprlang";
    };

    plugins = {
      treesitter = {
        enable = true;

        nixvimInjections = true;

        folding = true;
        indent = true;

        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          bash
          bicep
          c
          cmake
          cpp
          css
          c-sharp
          dockerfile
          dot
          fish
          go
          html
          hyprlang
          java
          javascript
          json
          json5
          latex
          make
          markdown
          lua
          nix
          norg
          python
          regex
          rust
          scss
          sql
          svelte
          toml
          tsx
          typescript
          yaml
          vim
        ];

      };

      treesitter-refactor = {
        enable = true;

        highlightDefinitions = {
          enable = true;
          clearOnCursorMove = true;
        };
        smartRename = {
          enable = true;
        };
        navigation = {
          enable = true;
        };
      };
    };
  };
}
