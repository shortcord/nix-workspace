{ name, config, pkgs, ... }: {
  age.secrets.keycloak-psql-password.file =
    ../../secrets/${name}/keycloak-psql-password.age;
  networking = { firewall = { allowedTCPPorts = [ 80 443 ]; }; };
  systemd = {
    network = {
      wait-online.anyInterface = true;
    };
  };
  services = {
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "${config.networking.fqdn}" = {
          kTLS = true;
          http2 = true;
          http3 = true;
          forceSSL = true;
          enableACME = true;

          locations."/" = {
            extraConfig = ''
              proxy_buffer_size 128k;
              proxy_buffers 4 256k;
              proxy_busy_buffers_size 256k;
            '';
            proxyPass = "http://127.0.0.1:${
                toString config.services.keycloak.settings.http-port
              }";
          };
        };
      };
    };
    mysql = {
      enable = true;
      package = pkgs.mariadb;
      initialDatabases = [{ name = "keycloak"; }];
      ensureUsers = [{
        name = "keycloak";
        ensurePermissions = {
          "keycloak.*" = "ALL PRIVILEGES";
          "*.*" = "SELECT, LOCK TABLES";
        };
      }];
    };
    keycloak = {
      enable = true;
      database = {
        type = "mariadb";
        createLocally = false;
        passwordFile = config.age.secrets.keycloak-psql-password.path;
      };
      settings = {
        hostname = "https://${config.networking.fqdn}";
        http-port = 8080;
        http-enabled = true;
        proxy-headers = "xforwarded";
        proxy-trusted-addresses = "127.0.0.0/8";
      };
    };
  };
}
