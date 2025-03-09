{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    # TODO: remove when it makes it to nixos-unstable
    firefox-devedition
    looking-glass-client
    linuxKernel
    tailscale
    # Broken hash on python
    vscode-extensions
    ;
}
