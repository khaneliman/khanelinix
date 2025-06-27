{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.nh;
in
{
  options.${namespace}.programs.terminal.tools.nh = {
    enable = lib.mkEnableOption "nh";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      package = inputs.nh.packages.${pkgs.stdenv.hostPlatform.system}.nh.overrideAttrs {
        patches = [
          (pkgs.fetchpatch {
            url = "https://github.com/nix-community/nh/pull/334.patch";
            hash = "sha256-21xHbxyyG6b8jMvMBSALZp+Z9nD1qfJ3zME3QsUfx38=";
          })
        ];
      };

      clean = {
        enable = true;
      };

      flake = "${config.home.homeDirectory}/khanelinix";
    };

    home = {
      sessionVariables = {
        NH_SEARCH_PLATFORM = 1;
      };
      shellAliases = {
        nixre = "nh ${if pkgs.stdenv.hostPlatform.isLinux then "os" else "darwin"} switch";
      };
    };
  };
}
