# Shared builder for nixd's flake-aware exprs, consumed by the Claude Code and
# opencode LSP modules. Curries the flake-detection helper (nixd-expr.nix) with
# this flake (`self`) + host `system`, then exposes the three exprs nixd reads:
# `nixpkgs` (cwd flake's nixpkgs, falling back to khanelinix), and the khanelinix
# `nixosOptions` / `homeManagerOptions` option trees.
{
  self,
  system,
}:
let
  wrapper = builtins.toFile "nixd-expr-wrapper.nix" ''
    import ${./nixd-expr.nix} {
      self = ${builtins.toJSON self.outPath};
      system = ${builtins.toJSON system};
    }
  '';
  withFlakes = expr: "with import ${wrapper}; ${expr}";
in
{
  nixpkgs = withFlakes "import (if local != null && (local.inputs.nixpkgs or null) != null then local.inputs.nixpkgs else global.inputs.nixpkgs) { }";
  nixosOptions = withFlakes "global.nixosConfigurations.khanelinix.options";
  homeManagerOptions = withFlakes "global.homeConfigurations.\"khaneliman@khanelinix\".options";
}
