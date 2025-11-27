{ lib }: lib.importSubdirs ./. { exclude = [ "default.nix" ]; }
