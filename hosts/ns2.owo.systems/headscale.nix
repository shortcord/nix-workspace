{ name, nodes, pkgs, lib, config, unstablePkgs, ... }:
let hsConf = config.services.headscale;
in {
  services = {
    headscale = {
      enable = true;
      package = unstablePkgs.headscale;
      address = "127.0.0.1";
      port = 7979;
      settings = {
        database = {
          type = "sqlite3";
          sqlite.path = "/var/lib/headscale/db.sqlite";
        };
        server_url = "https://headscale.${config.networking.fqdn}";
        dns = {
          magic_dns = true;
          base_domain = "ts.shortcord.com";
          nameservers.global =
            [ "9.9.9.9" "149.112.112.112" "2620:fe::fe" "2620:fe::9" ];
          use_username_in_magic_dns = true;
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
              extraConfig = ''
                proxy_hide_header 'Access-Control-Allow-Origin';
                proxy_hide_header 'Access-Control-Allow-Methods';
                proxy_hide_header 'Access-Control-Allow-Headers';

                if ($request_method = 'OPTIONS') {
                   add_header 'Access-Control-Allow-Origin' '*';
                   add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                   add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
                   add_header 'Content-Type' 'text/plain; charset=utf-8';
                   add_header 'Content-Length' 0;
                   return 204;
                }
                if ($request_method = 'POST') {
                   add_header 'Access-Control-Allow-Origin' '*' always;
                   add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
                   add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
                   add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
                }
                if ($request_method = 'GET') {
                   add_header 'Access-Control-Allow-Origin' '*' always;
                   add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
                   add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
                   add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
                }
              '';
            };
          };
        };
      };
    };
  };
}
