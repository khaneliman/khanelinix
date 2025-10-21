{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) getExe mkIf;

  cfg = config.khanelinix.programs.terminal.tools.bat;
in
{
  options.khanelinix.programs.terminal.tools.bat = {
    enable = lib.mkEnableOption "bat";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;

      config = {
        style = "auto,header-filesize";
      };

      extraPackages =
        with pkgs.bat-extras;
        [
          batdiff
          batman
          batpipe
          batwatch
          prettybat
        ]
        # FIXME: broken darwin
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          batgrep
        ];
    };

    home.shellAliases = {
      cat = "${getExe pkgs.bat} --style=plain";
    };
  };
}
