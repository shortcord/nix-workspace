{ pkgs, config, ... }: {
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    # Get around sandboxing issues, fuckin' developers
    checkConfig = "syntax-only";
    exporters = {
      node = {
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
            icmp_probe:
              prober: icmp
              timeout: 5s
              icmp:
                preferred_ip_protocol: "ip6"
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
        bearer_token_file = config.age.secrets.minioPrometheusBearerToken.path;
        scheme = "https";
        static_configs = [{ targets = [ "storage.owo.systems" ]; }];
      }
      {
        job_name = "blackbox-exporters";
        metrics_path = "/probe";
        params = { module = [ "icmp_probe" ]; };
        scrape_interval = "5s";
        scrape_timeout = "3s";
        static_configs = [{
          targets = [
            "home.shortcord.com"
            "router.cloud.shortcord.com"
            "maus.home.shortcord.com"
            "violet.lab.shortcord.com"
            "lilac.lab.shortcord.com"
          ];
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
        dns_sd_configs = [{
          names = [ "_node-exporter.prometheus.owo.systems" ];
          type = "SRV";
          refresh_interval = "5s";
        }];
      }
      {
        job_name = "powerdns-exporter";
        scheme = "https";
        metrics_path = "/metrics";
        dns_sd_configs = [{
          names = [ "_powerdns-exporter.owo.systems" ];
          type = "SRV";
          refresh_interval = "5s";
        }];
      }
    ];
  };
}
