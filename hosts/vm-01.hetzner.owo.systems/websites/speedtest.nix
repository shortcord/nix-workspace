{ pkgs, config, ... }:
let
  fqdn = "speedtest.${config.networking.fqdn}";
  webRoot = "/var/www/speedtest.owo.solutions";
in {
  services = {
    phpfpm.pools."speedtest" = {
      user = config.services.nginx.user;
      group = config.services.nginx.group;
      phpPackage = pkgs.php82;
      settings = {
        pm = "dynamic";
        "listen.owner" = config.services.nginx.user;
        "pm.max_children" = 5;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 3;
        "pm.max_requests" = 500;
      };
    };
    nginx = {
      virtualHosts = {
        "${fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          root = "${webRoot}";

          locations = {
            "/" = {
              index = "index.html";
              tryFiles = "$uri $uri/ /index.html?$query_string";
            };
            "~ \\.php$" = {
              extraConfig = ''
                fastcgi_pass unix:${
                  config.services.phpfpm.pools."speedtest".socket
                };
                fastcgi_index index.html;
              '';
            };
          };
        };
      };
    };
  };
}
