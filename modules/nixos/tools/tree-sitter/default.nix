{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.tree-sitter;
in
{
  options.khanelinix.tools.tree-sitter = {
    enable = mkBoolOpt false "Whether or not to enable tree-sitter.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      tree-sitter
      tree-sitter-grammars.tree-sitter-bash
      tree-sitter-grammars.tree-sitter-c
      tree-sitter-grammars.tree-sitter-c-sharp
      tree-sitter-grammars.tree-sitter-cpp
      tree-sitter-grammars.tree-sitter-css
      tree-sitter-grammars.tree-sitter-go
      tree-sitter-grammars.tree-sitter-html
      tree-sitter-grammars.tree-sitter-java
      tree-sitter-grammars.tree-sitter-javascript
      tree-sitter-grammars.tree-sitter-json
      tree-sitter-grammars.tree-sitter-lua
      tree-sitter-grammars.tree-sitter-python
      tree-sitter-grammars.tree-sitter-rust
      tree-sitter-grammars.tree-sitter-sql
      tree-sitter-grammars.tree-sitter-typescript
      tree-sitter-grammars.tree-sitter-vim
      tree-sitter-grammars.tree-sitter-yaml
    ];
  };
}
