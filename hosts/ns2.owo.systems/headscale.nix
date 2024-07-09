{ name, nodes, pkgs, lib, config, ... }:
let hsConf = config.services.headscale;
in {
  services = {
    headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 7979;
      settings = {
        server_url = "https://headscale.${config.networking.fqdn}";
        dns_config = {
          magic_dns = true;
          nameservers = [ "9.9.9.9" "9.9.8.8" ];
          base_domain = "ts.shortcord.com";
        };
        ip_prefixes = [ "100.64.0.0/10" "fd7a:115c:a1e0::/48" ];
        prefixes = {
          v4 = "100.64.0.0/10";
          v6 = "fd7a:115c:a1e0::/48";
        };
      };
    };
    nginx = {
      virtualHosts = {
        "headscale.${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = { 
              proxyWebsockets = true;
              proxyPass = "http://${hsConf.address}:${toString hsConf.port}";
            };
          };
        };
      };
    };
  };
}
