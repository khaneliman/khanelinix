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
    mkDefault
    ;
  inherit (lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.system.networking;
in
{
  options.khanelinix.system.networking = with types; {
    enable = lib.mkEnableOption "networking support";
    hosts = mkOpt attrs { } "An attribute set to merge with <option>networking.hosts</option>";
    optimizeTcp = mkBoolOpt false "Optimize TCP connections";
    manager = mkOpt (types.enum [
      "connman"
      "networkmanager"
      "systemd-networkd"
    ]) "systemd-networkd" "Network manager to use.";
    dns = mkOpt (types.enum [
      "dnsmasq"
      "systemd-resolved"
    ]) "systemd-resolved" "Dns resolver to use.";
  };

  config = mkIf cfg.enable {
    boot = {
      extraModprobeConfig = "options bonding max_bonds=0";

      kernelModules = [
        "af_packet"
      ]
      ++ lib.optionals cfg.optimizeTcp [
        "tls"
        "tcp_bbr"
      ]
      ++ [
        # Netfilter modules for connection tracking
        "nf_conntrack"
        "nf_conntrack_ftp"
        "nf_conntrack_netlink"
      ];

      kernel.sysctl = {
        # TCP hardening
        # Prevent bogus ICMP errors from filling up logs.
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        # Reverse path filtering causes the kernel to do source validation of
        # packets received from all interfaces. This can mitigate IP spoofing.
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;
        # Do not accept IP source route packets (we're not a router)
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        # Don't send ICMP redirects (again, we're on a router)
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        # Refuse ICMP redirects (MITM mitigations)
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        # Protects against SYN flood attacks
        "net.ipv4.tcp_syncookies" = 1;
        # Incomplete protection again TIME-WAIT assassination
        "net.ipv4.tcp_rfc1337" = 1;
        # And other stuff
        "net.ipv4.conf.all.log_martians" = true;
        "net.ipv4.conf.default.log_martians" = true;
        "net.ipv4.icmp_echo_ignore_broadcasts" = true;
        "net.ipv6.conf.default.accept_ra" = 1;
        "net.ipv6.conf.all.accept_ra" = 1;
        # Timestamps improve performance (PAWS, RTT estimation) - security concern is minimal
        "net.ipv4.tcp_timestamps" = 1;

        # Conntrack tuning
        "net.netfilter.nf_conntrack_generic_timeout" = 60;
        "net.netfilter.nf_conntrack_max" = 1048576;
        "net.netfilter.nf_conntrack_tcp_timeout_established" = 600;
        "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 1;
      }
      // lib.optionalAttrs cfg.optimizeTcp {
        # TCP optimization (enabled via optimizeTcp flag)
        # TCP Fast Open reduces latency by packing data in initial SYN
        "net.ipv4.tcp_fastopen" = 3;
        # BBR congestion control with fq qdisc (designed to work together)
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.core.default_qdisc" = "fq";

        # Buffer and connection tuning
        "net.core.optmem_max" = 65536;
        "net.core.rmem_default" = 1048576;
        "net.core.rmem_max" = 16777216;
        "net.core.somaxconn" = 8192;
        "net.core.wmem_default" = 1048576;
        "net.core.wmem_max" = 16777216;
        "net.ipv4.ip_local_port_range" = "16384 65535";
        "net.ipv4.tcp_max_syn_backlog" = 8192;
        "net.ipv4.tcp_max_tw_buckets" = 2000000;
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.ipv4.tcp_rmem" = "4096 1048576 16777216";
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_tw_reuse" = 1;
        "net.ipv4.tcp_wmem" = "4096 65536 16777216";
        "net.ipv4.udp_rmem_min" = 8192;
        "net.ipv4.udp_wmem_min" = 8192;
      };
    };

    # network tools that are helpful and nice to have
    environment.systemPackages = with pkgs; [
      mtr
      tcpdump
      traceroute
    ];

    khanelinix.user.extraGroups = [
      "network"
      "wireshark"
    ];

    networking = {
      hosts = {
        "127.0.0.1" = cfg.hosts."127.0.0.1" or [ ];
      }
      // cfg.hosts;

      firewall = {
        allowedUDPPorts = [
          # mDNS
          5353
        ];
        allowedTCPPorts = [
          443
          8080
        ];
        checkReversePath = mkDefault false;
        logReversePathDrops = true;
        logRefusedConnections = true;
      };

      nameservers = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];

      useDHCP = mkDefault false;
      usePredictableInterfaceNames = true;
    };
  };
}
