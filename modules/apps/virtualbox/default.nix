{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.virtualbox;
in {
  options.khanelinix.apps.virtualbox = with types; {
    enable = mkBoolOpt false "Whether or not to enable Virtualbox.";
  };

  config = mkIf cfg.enable {
    virtualisation.virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };

    khanelinix.user.extraGroups = ["vboxusers"];
  };
}
