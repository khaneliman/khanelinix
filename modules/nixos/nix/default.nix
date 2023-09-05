{ config
, lib
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.nix;
in
{
  imports = [ ../../shared/nix/default.nix ];

  config = mkIf cfg.enable {
    nix = {
      settings = {
        substituters = [
          "https://hyprland.cachix.org"
          "https://nix-community.cachix.org"
          "https://nix-gaming.cachix.org"
        ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };

      gc = {
        dates = "weekly";
      };
    };
  };
}
