{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    getExe'
    stringAfter
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.display-managers.gdm;
  gdmHome = config.users.users.gdm.home;
in
{
  options.${namespace}.display-managers.gdm = with types; {
    enable = lib.mkEnableOption "gdm";
    autoSuspend = mkBoolOpt true "Whether or not to suspend the machine after inactivity.";
    defaultSession = mkOpt (nullOr str) null "The default session to use.";
    monitors = mkOpt (nullOr path) null "The monitors.xml file to create.";
    wayland = mkBoolOpt true "Whether or not to use Wayland.";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules =
      [ "d ${gdmHome}/.config 0711 gdm gdm" ]
      ++ (
        # "./monitors.xml" comes from ~/.config/monitors.xml when GNOME
        # display information is updated.
        lib.optional (cfg.monitors != null) "L+ ${gdmHome}/.config/monitors.xml - - - - ${cfg.monitors}"
      );

    services = {
      libinput.enable = true;
      displayManager = {
        inherit (cfg) defaultSession;
        #FIXME: wtf
        sddm.enable = lib.mkForce false;
      };

      xserver = {
        enable = true;

        displayManager = {
          gdm = {
            inherit (cfg) enable wayland autoSuspend;
          };
        };
      };
    };

    system.activationScripts.postInstallGdm =
      stringAfter [ "users" ] # bash
        ''
          echo "Setting gdm permissions for user icon"
          ${getExe' pkgs.acl "setfacl"} -m u:gdm:x /home/${config.${namespace}.user.name}
          ${getExe' pkgs.acl "setfacl"} -m u:gdm:r /home/${config.${namespace}.user.name}/.face.icon || true
        '';
  };
}
