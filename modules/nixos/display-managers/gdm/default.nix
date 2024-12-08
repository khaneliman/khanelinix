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
    enable = mkBoolOpt false "Whether or not to enable gdm.";
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

    # systemd.services."${namespace}-user-icon" = {
    #   before = [ "display-manager.service" ];
    #   wantedBy = [ "display-manager.service" ];
    #
    #   script = # bash
    #     ''
    #       config_file=/var/lib/AccountsService/users/${config.${namespace}.user.name}
    #       icon_file=/run/current-system/sw/share/icons/user/${config.${namespace}.user.name}/${
    #         config.${namespace}.user.icon.fileName
    #       }
    #
    #       if ! [ -d "$(dirname "$config_file")" ]; then
    #         mkdir -p "$(dirname "$config_file")"
    #       fi
    #
    #       if ! [ -f "$config_file" ]; then
    #         echo "[User]
    #         Session=gnome
    #         SystemAccount=false
    #         Icon=$icon_file" > "$config_file"
    #       else
    #         icon_config=$(sed -E -n -e "/Icon=.*/p" $config_file)
    #
    #         if [[ "$icon_config" == "" ]]; then
    #           echo "Icon=$icon_file" >> $config_file
    #         else
    #           sed -E -i -e 's#^Icon=.*$#Icon=$icon_file#' $config_file
    #         fi
    #       fi
    #     '';
    #
    #   serviceConfig = {
    #     Type = "simple";
    #     User = "root";
    #     Group = "root";
    #   };
    # };
    #
    system.activationScripts.postInstallGdm =
      stringAfter [ "users" ] # bash
        ''
          echo "Setting gdm permissions for user icon"
          ${getExe' pkgs.acl "setfacl"} -m u:gdm:x /home/${config.${namespace}.user.name}
          ${getExe' pkgs.acl "setfacl"} -m u:gdm:r /home/${config.${namespace}.user.name}/.face.icon || true
        '';
  };
}
