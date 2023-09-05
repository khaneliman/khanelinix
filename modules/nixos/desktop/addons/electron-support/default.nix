{ options
, config
, lib
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.desktop.addons.electron-support;
in
{
  options.khanelinix.desktop.addons.electron-support = with types; {
    enable =
      mkBoolOpt false
        "Whether to enable electron support in the desktop environment.";
  };

  config = mkIf cfg.enable {
    khanelinix.home.configFile."electron-flags.conf".source =
      ./electron-flags.conf;

    environment.sessionVariables = { NIXOS_OZONE_WL = "1"; };
  };
}
