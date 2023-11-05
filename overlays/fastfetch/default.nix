{ channels, ... }: _final: prev: {
  inherit (channels.nixpkgs-master) fastfetch;
}
