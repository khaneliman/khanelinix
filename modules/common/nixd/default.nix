# Shared builder for nixd's flake-aware exprs, consumed by the Claude Code and
# opencode LSP modules. Curries the flake-detection helper (nixd-expr.nix) with
# this flake (`self`) + host `system`, then exposes the three exprs nixd reads:
# `nixpkgs` (cwd flake's nixpkgs, falling back to khanelinix), and the khanelinix
# `nixosOptions` / `homeManagerOptions` option trees.
{
  self,
  system,
  hostname ? null,
  username ? null,
}:
let
  wrapper = builtins.toFile "nixd-expr-wrapper.nix" ''
    import ${./nixd-expr.nix} {
      self = ${builtins.toJSON self.outPath};
      system = ${builtins.toJSON system};
    }
  '';
  withFlakes = expr: "with import ${wrapper}; ${expr}";
  optionsFor =
    output: name:
    if name == null then
      "{}"
    else
      withFlakes ''
        let name = ${builtins.toJSON name};
            configurations = flake: flake.${output} or {};
        in if local != null && builtins.hasAttr name (configurations local)
           then (builtins.getAttr name (configurations local)).options
           else if builtins.hasAttr name (configurations global)
           then (builtins.getAttr name (configurations global)).options
           else {}
      '';
in
{
  nixpkgs = withFlakes "import (if local != null && (local.inputs.nixpkgs or null) != null then local.inputs.nixpkgs else global.inputs.nixpkgs) { }";
  nixosOptions = optionsFor "nixosConfigurations" hostname;
  homeManagerOptions = optionsFor "homeConfigurations" (
    if username == null || hostname == null then null else "${username}@${hostname}"
  );
}
