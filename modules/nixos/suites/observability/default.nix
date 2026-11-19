{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.suites.observability;
  cacheAppdata = cfg.cacheAppdataDir;
  inherit (config.services.tailscale) interfaceName;
  exporterNames = cfg.exporters.collectors;
  prometheusExporters = config.services.prometheus.exporters;

  datasource = {
    type = "prometheus";
    uid = "fleet-prometheus";
  };
  dashboard = pkgs.writeTextDir "fleet.json" (
    builtins.toJSON {
      uid = "fleet-observability";
      title = "Fleet observability";
      schemaVersion = 39;
      panels =
        lib.imap1
          (id: panel: {
            inherit id datasource;
            inherit (panel) title;
            type = "timeseries";
            gridPos = {
              x = 0;
              y = (id - 1) * 8;
              w = 24;
              h = 8;
            };
            targets = [
              {
                refId = "A";
                inherit (panel) expr;
                legendFormat = "{{instance}}";
              }
            ];
            fieldConfig.defaults.unit = panel.unit;
          })
          [
            {
              title = "CPU utilization";
              unit = "percent";
              expr = ''100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval])))'';
            }
            {
              title = "Failed systemd units";
              unit = "short";
              expr = ''sum by (instance) (systemd_unit_state{state="failed"})'';
            }
            {
              title = "Disks failing SMART";
              unit = "short";
              expr = "sum by (instance) (smartctl_device_smart_status == bool 0)";
            }
          ];
    }
  );
in
{
  options.khanelinix.suites.observability = {
    enable = lib.mkEnableOption "observability suite";

    cacheAppdataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/cache/appdata";
      description = "Cache-backed application data directory.";
    };

    exporters = {
      collectors = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "node"
            "systemd"
            "smartctl"
          ]
        );
        default = [ ];
        description = ''
          Prometheus exporters to run on this host over Tailscale. Can be set
          without enabling the Grafana suite. Select smartctl only on hosts
          with disks to monitor; configure its device list via the NixOS exporter.
        '';
      };

      listenAddress = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.strMatching "100[.](6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])([.](25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){2}"
        );
        default = null;
        description = "This host's Tailscale IPv4 address, as reported by tailscale ip -4.";
      };
    };

    grafana.prometheusUrl = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "https?://[^/?#@[:space:]]+(/[^?#[:space:]]*)?");
      default = null;
      description = ''
        Base URL of an existing Prometheus server. When the suite is enabled,
        provision a datasource and fleet dashboard. Do not include credentials.
        Configure scrape targets on that server.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (exporterNames != [ ]) {
      assertions = [
        {
          assertion = cfg.exporters.listenAddress != null;
          message = "Observability exporters require exporters.listenAddress set to this host's Tailscale IPv4 address.";
        }
        {
          assertion = config.services.tailscale.enable && interfaceName != "userspace-networking";
          message = "Observability exporters require Tailscale with a tunnel interface.";
        }
      ];
    })

    (lib.mkIf (exporterNames != [ ] && cfg.exporters.listenAddress != null) {
      services.prometheus.exporters = lib.genAttrs exporterNames (_: {
        enable = true;
        inherit (cfg.exporters) listenAddress;
        openFirewall = false;
      });
      networking.firewall.interfaces.${interfaceName}.allowedTCPPorts = map (
        name: prometheusExporters.${name}.port
      ) exporterNames;

      systemd.services = lib.listToAttrs (
        map (
          name:
          lib.nameValuePair "prometheus-${name}-exporter" {
            wants = [ "tailscaled.service" ];
            after = [ "tailscaled.service" ];
            # Tailscaled can start before it has assigned the tunnel address.
            serviceConfig.RestartSec = lib.mkDefault "5s";
          }
        ) exporterNames
      );
    })

    {
      khanelinix.services.notify-failure.units = lib.mkDefault (
        lib.optionals config.services.snapraid.enable [
          "snapraid-sync.service"
          "snapraid-scrub.service"
        ]
        ++ lib.optional config.services.fstrim.enable "fstrim.service"
        ++ lib.optional (config.services.fast-nix-gc.enable or false) "fast-nix-gc.service"
        ++ map (name: "restic-backups-${name}.service") (builtins.attrNames config.services.restic.backups)
      );
    }

    (lib.mkIf cfg.enable {
      services = {
        systembus-notify.enable = lib.mkForce true;

        grafana = {
          enable = true;
          dataDir = "${cacheAppdata}/grafana";
          settings.server = {
            http_addr = "0.0.0.0";
            http_port = 3000;
          };
          provision = lib.mkIf (cfg.grafana.prometheusUrl != null) {
            enable = true;
            datasources.settings.datasources = [
              (
                datasource
                // {
                  name = "Fleet Prometheus";
                  url = cfg.grafana.prometheusUrl;
                }
              )
            ];
            dashboards.settings.providers = [
              {
                name = "Fleet";
                options.path = toString dashboard;
              }
            ];
          };
        };

        scrutiny = {
          enable = true;
          openFirewall = true;
        };

        uptime-kuma = {
          enable = true;
          settings.HOST = "0.0.0.0";
        };
      };

      networking.firewall.allowedTCPPorts = [
        3000
      ];
    })
  ];
}
