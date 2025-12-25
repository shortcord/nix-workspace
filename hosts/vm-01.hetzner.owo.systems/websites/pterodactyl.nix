{ pkgs, config, ... }: 
let
  webRoot = "/var/www/panel.owo.solutions";
in {
  environment.systemPackages = with pkgs; [
    php82
    php82Packages.composer
    unzip
  ];
  services = {
    mysql = { enable = true; };
    redis = {
      servers = {
        "pterodactyl" = {
          user = config.services.nginx.user;
          enable = true;
        };
      };
    };
    phpfpm.pools.pterodactyl = {
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
    mysqlBackup = {
        enable = true;
        databases = [
            "pterodactyl"
        ];
        calendar = "daily";
    };
    nginx = {
      virtualHosts = {
        "panel.owo.solutions" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          root = "${webRoot}/public";

          locations = {
            "/" = {
              index = "index.php";
              tryFiles = "$uri $uri/ /index.php?$query_string";
            };
            "~ \\.php$" = {
              extraConfig = ''
                fastcgi_pass unix:${config.services.phpfpm.pools.pterodactyl.socket};
                fastcgi_index index.php;
              '';
              fastcgiParams = { "test" = "test"; };
            };
          };
        };
      };
    };
  };
  systemd = {
    timers = {
      "pterodactyl-tasks" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnUnitActiveSec = "1m";
          Unit = "pterodactyl-tasks.service";
        };
      };
    };
    services = {
      "pterodactyl-tasks" = {
        script = ''
          set -eu
          ${pkgs.php82}/bin/php ${webRoot}/artisan schedule:run
        '';
        serviceConfig = {
          Type = "oneshot";
          User = config.services.nginx.user;
        };
      };
      "pterodactyl-queue-worker" = {
        wantedBy = [ "multi-user.target" ];
        startLimitIntervalSec = 180;
        startLimitBurst = 30;
        script = ''
          set -eu
          ${pkgs.php82}/bin/php ${webRoot}/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
        '';
        serviceConfig = {
          User = config.services.nginx.user;
          Group = config.services.nginx.group;
          Restart = "always";
          RestartSec="5s";
        };
      };
    };
  };
}
