{ options
, config
, lib
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.virtualbox;
in
{
  options.khanelinix.apps.virtualbox = with types; {
    enable = mkBoolOpt false "Whether or not to enable Virtualbox.";
  };

  config = mkIf cfg.enable {
    virtualisation.virtualbox.host = {
      enable = true;
      enableExtensionPack = true;
    };

    khanelinix.user.extraGroups = [ "vboxusers" ];
  };
}
