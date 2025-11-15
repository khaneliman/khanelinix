{ inputs }:
_final: prev: {
  inherit (inputs.self.packages.${prev.stdenv.hostPlatform.system})
    yabai
    ;
}
