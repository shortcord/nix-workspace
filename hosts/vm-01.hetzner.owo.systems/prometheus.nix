{ name, pkgs, lib, config, ... }:
let
  icmpTargets = [
    "home.shortcord.com"
    "router.cloud.shortcord.com"
    "maus.home.shortcord.com"
    "violet.lab.shortcord.com"
    "lilac.lab.shortcord.com"
    "miauws.life"
  ];
  nodeExporterTargets = [
    "pve.owo.solutions:9100"
    "miauws.life:9100"
    "vm-01.hetzner.owo.systems:9100"
    "violet.lab.shortcord.com:9100"
    "ipfs-pin-node-01.owo.systems:9100"
    "storage.owo.systems:9100"
    "lilac.lab.shortcord.com:9100"
    "maus.home.shortcord.com:9100"
    "node.02.servers.owo.solutions:9100"
  ];
  powerdnsExporterTargets = [
    "powerdns.vm-01.hetzner.owo.systems:443"
    "powerdns.ns2.owo.systems:443"
  ];

 in {
  age.secrets = {
    minioPrometheusBearerToken = {
      owner = "prometheus";
      group = "prometheus";
      file = ../../secrets/${name}/minioPrometheusBearerToken.age;
    };
    lokiConfig = {
      file = ../../secrets/${name}/lokiConfig.age;
      owner = config.services.loki.user;
      group = config.services.loki.group;
    };
    lokiBasicAuth = {
      file = ../../secrets/${name}/lokiBasicAuth.age;
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
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
        "loki.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          basicAuthFile = config.age.secrets.lokiBasicAuth.path;
          locations."/" = { proxyPass = "http://127.0.0.1:3100"; };
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
      retentionTime = "1y";
      webExternalUrl = "prometheus.${config.networking.fqdn}";
      # Get around sandboxing issues, fuckin' developers
      checkConfig = "syntax-only";
      exporters = {
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
          static_configs = [{
            targets = icmpTargets;
          }];
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
          static_configs = [{
            targets = icmpTargets;
          }];
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
          job_name = "node-exporters";
          static_configs = [{
            targets = nodeExporterTargets;
          }];
        }
        {
          job_name = "powerdns-exporter";
          scheme = "https";
          metrics_path = "/metrics";
          static_configs = [{
            targets = powerdnsExporterTargets;
          }];
        }
      ];
    };
    loki = {
      enable = true;
      configFile = config.age.secrets.lokiConfig.path;
    };
  };
}
