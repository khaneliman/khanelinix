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

      # Bat configuration
      # See: https://github.com/sharkdp/bat#configuration-file
      config = {
        style = "auto,header-filesize";
      };

      # FIXME: broken nushell darwin
      extraPackages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        with pkgs.bat-extras;
        [
          batdiff
          batgrep
          batman
          batpipe
          batwatch
          prettybat
        ]
      );
    };

    home.shellAliases = {
      cat = "${getExe pkgs.bat} --style=plain";
    };
  };
}
