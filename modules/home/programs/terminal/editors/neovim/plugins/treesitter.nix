_: {
  programs.nixvim = {
    plugins = {
      treesitter = {
        enable = true;

        folding = true;
        nixvimInjections = true;

        settings = {
          highlight = {
            additional_vim_regex_highlighting = true;
            enable = true;
            disable = null;
          };

          incremental_selection = {
            enable = true;
            keymaps = {
              init_selection = "gnn";
              node_incremental = "grn";
              scope_incremental = "grc";
              node_decremental = "grm";
            };
          };

          indent = {
            enable = true;
          };
        };

        # NOTE: Default is to install all grammars, here's a more concise list of ones i care about
        # grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        #   angular
        #   bash
        #   bicep
        #   c
        #   c-sharp
        #   cmake
        #   cpp
        #   css
        #   csv
        #   diff
        #   dockerfile
        #   dot
        #   fish
        #   git_config
        #   git_rebase
        #   gitattributes
        #   gitcommit
        #   gitignore
        #   go
        #   html
        #   hyprlang
        #   java
        #   javascript
        #   json
        #   json5
        #   jsonc
        #   kdl
        #   latex
        #   lua
        #   make
        #   markdown
        #   markdown_inline
        #   mermaid
        #   meson
        #   ninja
        #   nix
        #   norg
        #   objc
        #   python
        #   rasi
        #   readline
        #   regex
        #   rust
        #   scss
        #   sql
        #   ssh-config
        #   svelte
        #   swift
        #   terraform
        #   toml
        #   tsx
        #   typescript
        #   vim
        #   vimdoc
        #   xml
        #   yaml
        #   zig
        # ];
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
