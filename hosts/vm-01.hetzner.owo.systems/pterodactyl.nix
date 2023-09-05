{ pkgs, config, ... }: {
  environment.systemPackages = with pkgs; [
    php81
    php81Packages.composer
    unzip
  ];
  services = {
    mysql = { enable = true; };
    redis = { servers = { "pterodactyl" = { enable = true; }; }; };
    phpfpm.pools.pterodactyl = {
      user = "nobody";
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
        "panel.owo.solutions" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

            root = "/var/www/panel.owo.solutions";

          locations = {
            "/" = {
                tryFiles = "$uri $uri/ /index.php?$query_string";
            };
            "\.php$" = {
                fastcgiParams = {
                    "fastcgi_pass" = unix:${config.services.phpfpm.pools.pterodactyl.socket};
                };
            };
          };
        };
      };
    };
  };
}
