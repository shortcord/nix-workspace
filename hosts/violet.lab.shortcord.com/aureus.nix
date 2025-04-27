{ name, pkgs, lib, config, ... }:
let
  wwwRoot = "/var/www/aureus";
in {
  security.acme = {
    certs = {
      "erp.${config.networking.fqdn}" = {
        inheritDefaults = true;
        dnsProvider = "pdns";
        environmentFile = config.age.secrets.acmeCredentialsFile.path;
        webroot = null;
      };
    };
  };
  services.phpfpm.pools."aureus" = {
    user = config.services.nginx.user;
    group = config.services.nginx.group;
    phpPackage = pkgs.php83;
    settings = {
      pm = "dynamic";
      "listen.owner" = config.services.nginx.user;
      "pm.start_servers" = 1;
      "pm.max_children" = 5;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 2;
      "pm.max_requests" = 500;
    };
  };
  services.nginx = {
    virtualHosts = {
      "erp.${config.networking.fqdn}" = {
        kTLS = true;
        http2 = true;
        http3 = true;
        forceSSL = true;
        enableACME = true;

        root = "${wwwRoot}/public";

        locations = {
            "/" = {
                index = "index.php";
                tryFiles = "$uri $uri/ /index.php?$query_string";
            };
            "/favicon.ico" = {
                extraConfig = ''
                    log_not_found off;
                '';
            };
            "/robots.txt" = {
                extraConfig = ''
                    log_not_found off;
                '';
            };
            "~* \.(?:css(\.map)?|js(\.map)?|jpe?g|png|gif|ico|cur|heic|webp|tiff?|mp3|m4a|aac|ogg|midi?|wav|mp4|mov|webm|mpe?g|avi|ogv|flv|wmv)$" = {
                extraConfig = ''
                    expires 7d;
                '';
            };
            "~* \.(?:svgz?|ttf|ttc|otf|eot|woff2?)$" = {
                extraConfig = ''
                    add_header Access-Control-Allow-Origin "*";
                    expires 7d;
                '';
            };
            "~ \\.php$" = {
            extraConfig = ''
                fastcgi_pass unix:${config.services.phpfpm.pools."aureus".socket};
                fastcgi_index index.php;
            '';
            };
        };
      };
    };
  };
}
