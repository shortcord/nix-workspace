{ name, pkgs, lib, config, ... }:
let
  icmpTargets = [
    "home.shortcord.com"
    "router.cloud.shortcord.com"
    "maus.short.ts.shortcord.com"
    "violet.short.ts.shortcord.com"
    "ns2.owo.solutions"
  ];
  nodeExporterTargets = [
    "pve.owo.solutions:9100"
    "vm-01.hetzner.owo.systems:9100"
    "violet.short.ts.shortcord.com:9100"
    "ipfs-pin-node-01.owo.systems:9100"
    "ipfs-01.owo.systems:9100"
    "storage.owo.systems:9100"
    "maus.short.ts.shortcord.com:9100"
    "node.02.servers.owo.solutions:9100"
    "ns2.owo.solutions:9100"
    "octoprint.lab.shortcord.com:9100"
    "svc.rocky.shinx.dev:9100"
    "feta.short.ts.shortcord.com:9100"
    "lilac.short.ts.shortcord.com:9100"
  ];
  powerdnsExporterTargets =
    [ "powerdns.vm-01.hetzner.owo.systems:443" "powerdns.ns2.owo.systems:443" ];
  mysqldExporterTargets =
    [ "vm-01.hetzner.owo.systems:9104" "ns2.owo.systems:9104" ];
  processExporterTargets = [ "svc.rocky.shinx.dev:9256" ];
  apcupsdExporterTargets = [ "violet.short.ts.shortcord.com:9162" ];

in {
  age.secrets = {
    minioPrometheusBearerToken = {
      file = ../../secrets/${name}/minioPrometheusBearerToken.age;
      owner = "prometheus";
      group = "prometheus";
    };
    mysqldExporterConfig = {
      file = ../../secrets/${name}/mysqldExporterConfig.age;
      owner = "prometheus";
      group = "prometheus";
    };
  };
  services = {
    nginx = lib.mkIf config.services.nginx.enable {
      virtualHosts = {
        "prometheus.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass =
              "http://${toString config.services.prometheus.listenAddress}:${
                toString config.services.prometheus.port
              }";
          };
        };
      };
    };
    grafana = {
      enable = true;
      settings = {
        analytics = { reporting_enabled = false; };
        users = { allow_sign_up = false; };
        "auth.anonymous" = {
          enabled = false;
          org_name = "Main Org.";
          org_role = "Viewer";
          hide_version = true;
        };
        smtp = {
          enabled = true;
          host = "10.7.210.1:25";
          from_name = "${config.networking.fqdn}";
          from_address = "grafana-noreply@${config.networking.fqdn}";
        };
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = "grafana.${config.networking.fqdn}";
          root_url = "https://grafana.${config.networking.fqdn}";
        };
      };
    };
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9090;
      retentionTime = "6m";
      # Get around sandboxing issues, fuckin' developers
      checkConfig = "syntax-only";
      exporters = {
        mysqld = {
          enable = true;
          openFirewall = true;
          configFile = config.age.secrets.mysqldExporterConfig.path;
        };
        node = {
          enable = true;
          openFirewall = true;
        };
        systemd = {
          enable = true;
          openFirewall = true;
        };
        blackbox = {
          enable = true;
          openFirewall = false;
          configFile = pkgs.writeText "blackbox-config" ''
            modules:
              http_2xx:
                prober: http
                timeout: 5s
                http:
                  valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
                  valid_status_codes: [ 200 ]
                  method: GET
                  follow_redirects: true
                  fail_if_ssl: false
                  fail_if_not_ssl: true
                  preferred_ip_protocol: "ip6"
                  ip_protocol_fallback: true
              icmp6_probe:
                prober: icmp
                timeout: 2s
                icmp:
                  preferred_ip_protocol: "ip6"
                  ip_protocol_fallback: false
              icmp4_probe:
                prober: icmp
                timeout: 2s
                icmp:
                  preferred_ip_protocol: "ip4"
                  ip_protocol_fallback: false
          '';
        };
      };
      globalConfig = {
        evaluation_interval = "1m";
        scrape_interval = "5s";
      };
      scrapeConfigs = [
        {
          job_name = "minio-job";
          metrics_path = "/minio/v2/metrics/cluster";
          bearer_token_file =
            config.age.secrets.minioPrometheusBearerToken.path;
          scheme = "https";
          static_configs = [{ targets = [ "storage.owo.systems" ]; }];
        }
        {
          job_name = "icmp6-probes";
          metrics_path = "/probe";
          params = { module = [ "icmp6_probe" ]; };
          scrape_interval = "5s";
          scrape_timeout = "3s";
          static_configs = [{ targets = icmpTargets; }];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:9115";
            }
          ];
        }
        {
          job_name = "icmp4-probes";
          metrics_path = "/probe";
          params = { module = [ "icmp4_probe" ]; };
          scrape_interval = "5s";
          scrape_timeout = "3s";
          static_configs = [{ targets = icmpTargets; }];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:9115";
            }
          ];
        }
        {
          job_name = "mysqld-exporters";
          static_configs = [{ targets = mysqldExporterTargets; }];
        }
        {
          job_name = "node-exporters";
          static_configs = [{ targets = nodeExporterTargets; }];
        }
        {
          job_name = "process-exporter";
          static_configs = [{ targets = processExporterTargets; }];
        }
        {
          job_name = "apcupsd-exporter";
          static_configs = [{ targets = apcupsdExporterTargets; }];
        }
        {
          job_name = "powerdns-exporter";
          scheme = "https";
          metrics_path = "/metrics";
          static_configs = [{ targets = powerdnsExporterTargets; }];
        }
        {
          job_name = "octoprint-exporter";
          scheme = "https";
          metrics_path = "/prom-metrics";
          scrape_interval = "5s";
          scrape_timeout = "3s";
          static_configs =
            [{ targets = [ "printer1.feta.shortcord.com" "printer2.feta.shortcord.com" ]; }];
        }
        {
          job_name = "klipper-exporter";
          scheme = "https";
          metrics_path = "/prom-metrics";
          scrape_interval = "5s";
          scrape_timeout = "3s";
          static_configs =
            [{ targets = [ "printer3.feta.shortcord.com" ]; }];
        }
      ];
    };
  };
}
