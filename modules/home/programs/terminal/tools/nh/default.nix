{
  config,
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
      package = pkgs.nh.overrideAttrs {
        patches = [
          (pkgs.fetchpatch {
            url = "https://github.com/nix-community/nh/pull/340.patch";
            hash = "sha256-AYrogYKEbwCO4MWoiGIt9I5gDv8XiPEA7DiPaYtNnD8=";
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
