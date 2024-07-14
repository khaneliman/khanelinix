{ channels, ... }: _final: _prev: { inherit (channels.nixpkgs-small) clamav swiftPackages; }
