{ config, ... }:
{
  programs.nixvim = {
    plugins = {
      treesitter = {
        enable = true;

        nixvimInjections = true;

        folding = true;
        indent = true;

        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          angular
          bash
          bicep
          c
          c-sharp
          cmake
          cpp
          css
          csv
          diff
          dockerfile
          dot
          fish
          git_config
          git_rebase
          gitattributes
          gitcommit
          gitignore
          go
          html
          hyprlang
          java
          javascript
          json
          json5
          jsonc
          kdl
          latex
          lua
          make
          markdown
          markdown_inline
          mermaid
          meson
          ninja
          nix
          norg
          objc
          python
          rasi
          readline
          regex
          rust
          scss
          sql
          ssh-config
          svelte
          swift
          terraform
          toml
          tsx
          typescript
          vim
          vimdoc
          xml
          yaml
          zig
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
