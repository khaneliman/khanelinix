{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.desktop.addons.nautilus;
in
{
  options.khanelinix.desktop.addons.nautilus = {
    enable = mkBoolOpt false "Whether to enable the gnome file manager.";
  };

  config = mkIf cfg.enable {
    # Enable support for browsing samba shares.
    services.gvfs.enable = true;
    networking.firewall.extraCommands = "iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns";

    environment.systemPackages = with pkgs; [ gnome.nautilus ];
  };
}
