{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.nix-search-tv;
in
{
  options.khanelinix.programs.terminal.tools.nix-search-tv = {
    enable = lib.mkEnableOption "nix-search-tv";
  };

  config = mkIf cfg.enable {
    programs.nix-search-tv = {
      enable = true;

      settings = {
        indexes = [
          "nixpkgs"
          "home-manager"
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          "nixos"
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          "nix-darwin"
        ];
      };
    };
  };
}
