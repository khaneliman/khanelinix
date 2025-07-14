{ inputs, mkPkgs, ... }:
final: _prev: 
let
  master = mkPkgs inputs.nixpkgs-master final.system final.config;
in {
  inherit (master)
    # Fast updating / want latest always
    claude-code
    yaziPlugins
    ;
}
