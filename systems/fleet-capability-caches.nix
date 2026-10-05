{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  enabled = path: lib.attrByPath ([ "khanelinix" ] ++ path ++ [ "enable" ]) false config;
  cacheIf =
    condition: url: key:
    lib.mkIf condition {
      nix.settings = {
        substituters = [ url ];
        trusted-public-keys = [ key ];
      };
    };
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  username = config.khanelinix.user.name;
  anyrunEnabled =
    username != null
    && lib.attrByPath [
      "home-manager"
      "users"
      username
      "khanelinix"
      "programs"
      "graphical"
      "launchers"
      "anyrun"
      "enable"
    ] false config;
in
{
  config = lib.mkMerge [
    (cacheIf
      (
        isLinux
        && enabled [
          "suites"
          "wlroots"
        ]
      )
      "https://nixpkgs-wayland.cachix.org"
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    )
    (cacheIf
      (
        isLinux
        && enabled [
          "suites"
          "games"
        ]
      )
      "https://nix-gaming.cachix.org"
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    )
    (cacheIf
      (
        isLinux
        && enabled [
          "programs"
          "graphical"
          "wms"
          "hyprland"
        ]
      )
      "https://hyprland.cachix.org"
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    )
    (cacheIf (
      isLinux
      && inputs ? niri
      && enabled [
        "programs"
        "graphical"
        "wms"
        "niri"
      ]
    ) "https://niri.cachix.org" "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=")
    (cacheIf (
      enabled [
        "suites"
        "development"
      ]
      && (config.khanelinix.suites.development.aiEnable or false)
    ) "https://numtide.cachix.org" "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=")
    (cacheIf (
      isLinux && config.khanelinix.nix.enable && anyrunEnabled
    ) "https://anyrun.cachix.org" "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s=")
  ];
}
