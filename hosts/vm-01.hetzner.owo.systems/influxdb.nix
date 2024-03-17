{ pkgs, lib, config, ... }:
let cfg = config.services.influxdb2;
in {
  services = {
    influxdb2 = {
      enable = true;
      settings = { http-bind-address = "127.0.0.1:8086"; };
    };
    nginx = {
      virtualHosts = {
        "influxdb.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${toString cfg.settings.http-bind.address}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
