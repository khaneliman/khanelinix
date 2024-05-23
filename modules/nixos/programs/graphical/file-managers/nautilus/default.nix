{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.file-managers.nautilus;
in
{
  options.${namespace}.programs.graphical.file-managers.nautilus = {
    enable = mkBoolOpt false "Whether to enable the gnome file manager.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gnome.nautilus ];

    networking.firewall.extraCommands = "iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns";

    # Enable support for browsing samba shares.
    services.gvfs.enable = true;
  };
}
