{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    types
    mkIf
    getExe'
    stringAfter
    ;
  inherit (lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.display-managers.gdm;
  gdmHome = config.users.users.gdm.home;
in
{
  options.khanelinix.display-managers.gdm = with types; {
    enable = lib.mkEnableOption "gdm";
    autoSuspend = mkBoolOpt true "Whether or not to suspend the machine after inactivity.";
    defaultSession = mkOpt (nullOr str) null "The default session to use.";
    monitors = mkOpt (nullOr path) null "The monitors.xml file to create.";
    wayland = mkBoolOpt true "Whether or not to use Wayland.";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${gdmHome}/.config 0711 gdm gdm"
    ]
    ++ (
      # "./monitors.xml" comes from ~/.config/monitors.xml when GNOME
      # display information is updated.
      lib.optional (cfg.monitors != null) "L+ ${gdmHome}/.config/monitors.xml - - - - ${cfg.monitors}"
    );

    services = {
      displayManager = {
        inherit (cfg) defaultSession;
        gdm = {
          inherit (cfg) enable wayland autoSuspend;
        };
        #FIXME: wtf
        sddm.enable = lib.mkForce false;
      };
      libinput.enable = true;
      xserver.enable = true;
    };

    system.activationScripts.postInstallGdm =
      stringAfter [ "users" ] # bash
        ''
          echo "Setting gdm permissions for user icon"
          ${getExe' pkgs.acl "setfacl"} -m u:gdm:x /home/${config.khanelinix.user.name}
          ${getExe' pkgs.acl "setfacl"} -m u:gdm:r /home/${config.khanelinix.user.name}/.face.icon || true
        '';
  };
}
