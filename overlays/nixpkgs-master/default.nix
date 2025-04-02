{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    # Broken from introduced throw
    gitlint
    ;
}
