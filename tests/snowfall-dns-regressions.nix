{
  nixpkgs,
  repo ? ../.,
  moduleRoot ? repo + "/templates/snowfall/modules/nixos/system/networking",
}:
let
  namespace = "khanelisnow";
  baseLib = import (nixpkgs + "/lib");
  lib = baseLib.extend (
    _: _: {
      ${namespace} = import (repo + "/templates/snowfall/lib/module") { lib = baseLib; };
    }
  );
  # Isolate the real parent interface, not its unrelated incomplete scaffold.
  parentOptions =
    {
      config,
      lib,
      pkgs,
      namespace,
      ...
    }:
    {
      inherit
        (
          (import (moduleRoot + "/default.nix") {
            inherit
              config
              lib
              pkgs
              namespace
              ;
          })
        )
        options
        ;
    };
  children = [
    (moduleRoot + "/dnsmasq")
    (moduleRoot + "/resolved")
  ];
  evaluate =
    includeChildren: feature: extra:
    import (nixpkgs + "/nixos/lib/eval-config.nix") {
      inherit lib;
      system = "x86_64-linux";
      specialArgs = { inherit namespace; };
      modules = [
        parentOptions
        { ${namespace}.system.networking = feature; }
      ]
      ++ lib.optionals includeChildren children
      ++ [ extra ];
    };
  snapshot =
    evaluation:
    let
      c = evaluation.config;
      o = evaluation.options;
    in
    {
      dnsmasq = {
        inherit (c.services.dnsmasq) enable resolveLocalQueries settings;
        priority = o.services.dnsmasq.enable.highestPrio;
      };
      resolved = {
        inherit (c.services.resolved) enable;
        settings = c.services.resolved.settings.Resolve;
        priority = o.services.resolved.enable.highestPrio;
      };
      networkmanagerDns = c.networking.networkmanager.dns;
      inherit (c.networking) nameservers;
      resolvconf = {
        inherit (c.networking.resolvconf) enable useLocalResolver;
      };
      resolverUnits = builtins.filter (
        name:
        builtins.elem name [
          "dnsmasq"
          "systemd-resolved"
        ]
      ) (builtins.attrNames c.systemd.services);
    };
  backends = [
    "dnsmasq"
    "systemd-resolved"
  ];
  plain = { };
  mergeContribution = { lib, ... }: {
    networking.nameservers = [ "9.9.9.9" ];
    services = {
      dnsmasq.settings = {
        server = lib.mkAfter [ "149.112.112.112" ];
        cache-size = 321;
      };
      resolved.settings.Resolve = {
        Domains = lib.mkAfter [ "example.test" ];
        FallbackDNS = lib.mkAfter [ "149.112.112.112" ];
        DNSSEC = true;
      };
    };
  };
  upstreams = {
    defaults = plain;
    custom = mergeContribution;
    independentDnsmasq = {
      services.dnsmasq.enable = true;
    };
    independentResolved = {
      services.resolved.enable = true;
    };
  };
  disabled = lib.genAttrs backends (
    dns:
    lib.mapAttrs (
      _: extra:
      let
        feature = {
          enable = false;
          inherit dns;
        };
        actual = snapshot (evaluate true feature extra);
        expected = snapshot (evaluate false feature extra);
      in
      {
        inherit actual expected;
        pass = actual == expected;
      }
    ) upstreams
  );
  defaultDisabled = {
    actual = snapshot (evaluate true { } plain);
    expected = snapshot (evaluate false { } plain);
  };
  enabled = lib.genAttrs backends (
    dns:
    lib.genAttrs [ "plain" "merged" ] (
      kind:
      snapshot (
        evaluate true {
          enable = true;
          inherit dns;
        } (if kind == "plain" then plain else mergeContribution)
      )
    )
  );
  cfg = enabled;
  failures = lib.runTests {
    testDefaultEnabled = {
      expr = snapshot (evaluate true { enable = true; } plain);
      expected = enabled.systemd-resolved.plain;
    };
    testDefaultDisabled = {
      expr = defaultDisabled.actual;
      inherit (defaultDisabled) expected;
    };
    testDisabledMatrix = {
      expr = lib.all (
        dns: lib.all (name: disabled.${dns}.${name}.pass) (builtins.attrNames upstreams)
      ) backends;
      expected = true;
    };
    testDnsmasqEnabled = {
      expr = {
        inherit (cfg.dnsmasq.plain.dnsmasq) enable resolveLocalQueries;
        servers = cfg.dnsmasq.plain.dnsmasq.settings.server;
        resolved = cfg.dnsmasq.plain.resolved.enable;
        dns = cfg.dnsmasq.plain.networkmanagerDns;
        forcePriority = cfg.dnsmasq.plain.resolved.priority;
        localhost = builtins.elem "127.0.0.1" cfg.dnsmasq.plain.nameservers;
      };
      expected = {
        enable = true;
        resolveLocalQueries = true;
        servers = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        resolved = false;
        dns = "dnsmasq";
        forcePriority = 50;
        localhost = true;
      };
    };
    testResolvedEnabled = {
      expr = {
        inherit (cfg.systemd-resolved.plain.resolved) enable;
        settings = removeAttrs cfg.systemd-resolved.plain.resolved.settings [ "DNS" ];
        dnsmasq = cfg.systemd-resolved.plain.dnsmasq.enable;
        dns = cfg.systemd-resolved.plain.networkmanagerDns;
        forcePriority = cfg.systemd-resolved.plain.dnsmasq.priority;
      };
      expected = {
        enable = true;
        settings = {
          Domains = [ "~." ];
          DNSOverTLS = "true";
          DNSSEC = false;
          FallbackDNS = [ "192.168.1.1" ];
        };
        dnsmasq = false;
        dns = "systemd-resolved";
        forcePriority = 50;
      };
    };
    testDnsmasqMerge = {
      expr = {
        servers = cfg.dnsmasq.merged.dnsmasq.settings.server;
        cache = cfg.dnsmasq.merged.dnsmasq.settings.cache-size;
        conf = cfg.dnsmasq.merged.dnsmasq.settings.conf-file;
        resolv = cfg.dnsmasq.merged.dnsmasq.settings.resolv-file;
        localhost = cfg.dnsmasq.merged.resolvconf.useLocalResolver;
      };
      expected = {
        servers = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
          "149.112.112.112"
        ];
        cache = [ 321 ];
        conf = [ "/etc/dnsmasq-conf.conf" ];
        resolv = [ "/etc/dnsmasq-resolv.conf" ];
        localhost = true;
      };
    };
    testResolvedMerge = {
      expr = cfg.systemd-resolved.merged.resolved.settings;
      expected = {
        DNS = [ "9.9.9.9" ];
        Domains = [
          "~."
          "example.test"
        ];
        DNSOverTLS = "true";
        DNSSEC = true;
        FallbackDNS = [
          "192.168.1.1"
          "149.112.112.112"
        ];
      };
    };
  };
in
{
  inherit
    failures
    enabled
    disabled
    defaultDisabled
    ;
  pass = failures == [ ];
}
