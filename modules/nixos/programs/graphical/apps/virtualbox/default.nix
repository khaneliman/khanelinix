{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.apps.virtualbox;
in
{
  options.khanelinix.programs.graphical.apps.virtualbox = {
    enable = lib.mkEnableOption "Virtualbox";
  };

  config = mkIf cfg.enable {
    khanelinix.user.extraGroups = [ "vboxusers" ];

    virtualisation.virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };
  };
}
