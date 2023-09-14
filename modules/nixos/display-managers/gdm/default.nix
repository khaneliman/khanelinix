{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf getExe';
  inherit (lib.internal) mkBoolOpt mkOpt stringAfter;

  cfg = config.khanelinix.display-managers.gdm;
  gdmHome = config.users.users.gdm.home;
in
{
  options.khanelinix.display-managers.gdm = with types; {
    enable = mkBoolOpt false "Whether or not to enable gdm.";
    wayland = mkBoolOpt true "Whether or not to use Wayland.";
    autoSuspend =
      mkBoolOpt true "Whether or not to suspend the machine after inactivity.";
    monitors = mkOpt (nullOr path) null "The monitors.xml file to create.";
    defaultSession = mkOpt (nullOr str) null "The default session to use.";
  };

  config =
    mkIf cfg.enable
      {
        systemd.tmpfiles.rules =
          [
            "d ${gdmHome}/.config 0711 gdm gdm"
          ]
          ++ (
            # "./monitors.xml" comes from ~/.config/monitors.xml when GNOME
            # display information is updated.
            lib.optional (cfg.monitors != null) "L+ ${gdmHome}/.config/monitors.xml - - - - ${cfg.monitors}"
          );

        services.xserver = {
          enable = true;

          libinput.enable = true;
          displayManager = {
            inherit (cfg) defaultSession;

            gdm = {
              inherit (cfg) enable wayland autoSuspend;
            };
          };
        };

        systemd.services.khanelinix-user-icon = {
          before = [ "display-manager.service" ];
          wantedBy = [ "display-manager.service" ];

          serviceConfig = {
            Type = "simple";
            User = "root";
            Group = "root";
          };

          script = ''
            config_file=/var/lib/AccountsService/users/${config.khanelinix.user.name}
            icon_file=/run/current-system/sw/share/icons/user/${config.khanelinix.user.name}/${config.khanelinix.user.icon.fileName}

            if ! [ -d "$(dirname "$config_file")" ]; then
              mkdir -p "$(dirname "$config_file")"
            fi

            if ! [ -f "$config_file" ]; then
              echo "[User]
              Session=gnome
              SystemAccount=false
              Icon=$icon_file" > "$config_file"
            else
              icon_config=$(sed -E -n -e "/Icon=.*/p" $config_file)

              if [[ "$icon_config" == "" ]]; then
                echo "Icon=$icon_file" >> $config_file
              else
                sed -E -i -e 's#^Icon=.*$#Icon=$icon_file#' $config_file
              fi
            fi
          '';
        };

        system.activationScripts.postInstallGdm = stringAfter [ "users" ] ''
          echo "Setting gdm permissions for user icon"
          ${getExe' pkgs.acl "setfacl"} -m u:gdm:x /home/${config.khanelinix.user.name}
          ${getExe' pkgs.acl "setfacl"} -m u:gdm:r /home/${config.khanelinix.user.name}/.face.icon || true
        '';
      };
}
