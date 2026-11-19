# Shared builder for nixd's flake-aware exprs, consumed by the Claude Code and
# opencode LSP modules. Curries the flake-detection helper (nixd-expr.nix) with
# this flake (`self`) + host `system` to expose the package set and option trees
# from the current flake, falling back to khanelinix.
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
  darwinOptions = optionsFor "darwinConfigurations" hostname;
  homeManagerOptions = optionsFor "homeConfigurations" (
    if username == null || hostname == null then null else "${username}@${hostname}"
  );
}
