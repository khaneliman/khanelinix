{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.graphical.apps.virtualbox;
in
{
  options.${namespace}.programs.graphical.apps.virtualbox = {
    enable = lib.mkEnableOption "Virtualbox";
  };

  config = mkIf cfg.enable {
    ${namespace}.user.extraGroups = [ "vboxusers" ];

    virtualisation.virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };
  };
}
