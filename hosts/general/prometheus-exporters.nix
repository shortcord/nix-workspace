{ config, pkgs, ... }:
let cfg = config.services.prometheus.exporters;
in {
  services = {
    nginx = {
      virtualHosts = {
        "prometheus-exporters.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations = {
            "/node" = lib.mkIf cfg.node.enable {
              proxyPass =
                "http://${cfg.node.listenAddress}:${cfg.exporters.node.port}}/metrics";
            };
            "/systemd" = lib.mkIf cfg.systemd.enable {
              proxyPass =
                "http://${cfg.exporters.systemd.listenAddress}:${cfg.exporters.systemd.port}}/metrics";
            };
          };
        };
      };
    };
    prometheus = {
      exporters = {
        node = {
          enable = true;
          listenAddress = "127.0.0.2";
        };
        systemd = {
          enable = true;
          listenAddress = "127.0.0.2";
        };
      };
    };
  };
}
