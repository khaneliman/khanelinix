{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.display-managers.sddm;
in
{
  options.khanelinix.display-managers.sddm = with types; {
    enable = mkBoolOpt false "Whether or not to enable sddm.";
    defaultSession = mkOpt (nullOr types.str) null "The default session to use.";
  };

  config =
    mkIf cfg.enable
      {
        environment.systemPackages = with pkgs; [
          sddm
          khanelinix.catppuccin-sddm-corners
        ];

        services.xserver = {
          enable = true;

          libinput.enable = true;
          displayManager = {
            inherit (cfg) defaultSession;

            sddm = {
              inherit (cfg) enable;
              theme = "catppuccin-sddm-corners";

              settings = {
                General = {
                  GreeterEnvironment = "QT_PLUGIN_PATH=${pkgs.plasma5Packages.layer-shell-qt}/${pkgs.plasma5Packages.qtbase.qtPluginPrefix},QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
                  DisplayServer = "wayland";
                  InputMethod = "";
                };
                Wayland.CompositorCommand = "${pkgs.kwin}/bin/kwin_wayland --no-global-shortcuts --no-lockscreen --locale1";
              };
            };
          };
        };

        system.activationScripts.postInstallSddm = stringAfter [ "users" ] ''
          echo "Setting sddm permissions for user icon"
          ${pkgs.acl}/bin/setfacl -m u:sddm:x /home/${config.khanelinix.user.name}
          ${pkgs.acl}/bin/setfacl -m u:sddm:r /home/${config.khanelinix.user.name}/.face.icon || true
        '';
      };
}
